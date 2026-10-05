"""Builds the Hexile graphics for KadoKadeo from the original SWF (gfx.swf).

Hexile has little nested logic: every picture is rendered at x2 ("simple renders" pipeline) and the code places
them like the timelines of the original did.
  - mcHex: one picture per type and decor variant, the base raised by its height (Socle.setType) and cut by the mask
    of the clip (shape 62, Dirt and Mountain), with the random texture (sprite 23, 7 frames) of the base; the same
    pictures brightened by Col.setColor(root, 0, 20) (the hex under the mouse);
  - the soldiers the base timelines place (sprites 61, 35, 65: one frame per number of soldiers) are drawn by the
    code from the positions read here, with their shadows (shape 24 at 30 %);
  - mcSoldat: standing, ball (jump) and the victory dance (sprite 30), in both team colours (frame 1 / 2), standing
    also under Col.setPercentColor(sol, 30, 0xFFFFFF) (the blinking soldiers);
  - mcCastle: its 7 texture variants (base frame 1, island top smc frame 2), the soldiers drawn by the code;
  - brushSeaside: the 5 frames, in the 6 rotations and the 2 alphas of its smc that Game.terraforming draws into
    the sea bitmap (the bitmap itself is composed at run time: it depends on the island);
  - the hit areas of the hex pictures (mouse: the hex under the pointer), as run-length masks;
  - text fields: the digits of the embedded Impact laid out like Flash, with the filters of the fields baked as layers
    (interface counters + the GlowFilter of Game.initInter, castle counter), the 3 messages (mcMsg) rendered by FFDec
    from copies of gfx.swf holding their text, with the GlowFilter of Game.newMsg baked.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: hexile_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/hexile holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'hexile', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z

pivots = {}
area = {}
meta = {}

# symbols (gfx.swf ids)
S_SEL, S_RAY, S_ONDE, S_DRIP, S_SOLDAT, S_SMC, S_DANCE = 2, 5, 8, 10, 34, 33, 30
S_CASTLE, S_STAR, S_MSG, S_MSG_SMC, S_SHADE, S_INTER, S_BRUSH, S_HEX = 41, 43, 46, 45, 47, 51, 59, 66
S_ISLE, S_TEX = 15, 23                  # base.smc of Dirt / castle (2 tops), texture of the bases (7 frames)
B_BEACH, B_DIRT, B_MOUNT = 61, 35, 65   # the bases (`base`) of mcHex frames 1, 2, 3
SH_SHADOW = 24                          # shadow under the soldiers of sprite 35 (also mcShade)


def save_anim(name, imgs, reg):
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    w, h = imgs[0].size
    for i, im in enumerate(imgs):
        assert im.size == (w, h)
        im.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(reg[0] / w, 6), round(reg[1] / h, 6)]
    a = 0
    for im in imgs:
        bb = im.split()[3].getbbox()
        if bb:
            a += (bb[2] - bb[0]) * (bb[3] - bb[1])
    area[name] = a


def instance(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def cmds_inst(inst, M=R.IDENT, cx=R.NOCX):
    out = []
    R.Renderer(G, K).collect(inst, M, cx, set(), out)
    return out


def cmds_of(sid, ctrl=None, M=R.IDENT, cx=R.NOCX):
    return cmds_inst(instance(sid, ctrl), M, cx)


def render(items, pad=0.5):
    """items: command lists, or (commands, post) pairs, drawn on one common canvas (x4, reduced to x2);
    post(canvas) runs at x4 before the reduction. Returns (images, registration in px)."""
    items = [it if isinstance(it, tuple) else (it, None) for it in items]
    rd = R.Renderer(G, K)
    bb = None
    for cmds, _ in items:
        b = rd.bounds(cmds)
        if b:
            bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    step = 1.0 / K
    ox = math.floor((bb[0] - pad) / step) * step
    oy = math.floor((bb[1] - pad) / step) * step
    ex = math.ceil((bb[2] + pad) / step) * step
    ey = math.ceil((bb[3] + pad) / step) * step
    Wz, Hz = int(round((ex - ox) * Z)), int(round((ey - oy) * Z))
    w, h = int(round((ex - ox) * K)), int(round((ey - oy) * K))
    imgs = []
    for cmds, post in items:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        if post:
            canvas = post(canvas)
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        imgs.append(im.resize((w, h), Image.LANCZOS).convert('RGBA'))
    return imgs, (-ox * K, -oy * K)


def color_tf(mult, add):
    """a Flash colour transform on the composed clip (multipliers, offsets in 0..255): on straight colours"""
    m = np.array(mult, dtype=np.float32)
    a_ = np.array(add, dtype=np.float32) / 255.0

    def f(canvas):
        a = canvas[..., 3:4]
        rgb = np.where(a > 0, canvas[..., :3] / np.maximum(a, 1e-6), 0)
        rgb = np.clip(rgb * m + a_, 0, 1)
        return np.concatenate([rgb * a, a], axis=-1).astype(np.float32)
    return f


# Col.setColor(root, 0, 20): offsets +20, multipliers 100 % (the hex under the mouse)
HOVER = color_tf([1, 1, 1], [20, 20, 20])
# Col.setPercentColor(sol, 30, 0xFFFFFF): multipliers int(100 - 30) %, offsets int(0.3 * 255)
BLINK = color_tf([0.70, 0.70, 0.70], [76, 76, 76])


def with_entry(inst, name, **kw):
    """changes the placement of a named child (matrix offset / colour transform set by the code)"""
    for d, e in inst.display.items():
        if e['name'] == name:
            if 'dy' in kw:
                e['matrix'] = dict(e['matrix'], ty=e['matrix']['ty'] + kw['dy'])
            if 'alpha' in kw:
                e['cx'] = dict(mult=[1.0, 1.0, 1.0, kw['alpha']], add=[0, 0, 0, 0])
            return inst
    raise KeyError(name)


def twips(v):
    return round(v * 20) / 20.0


# ---------------------------------------------------------------- hexes
TEX = range(1, 8)
DIRT = [(3, 1), (8, 2)]                # Socle.setType(Dirt): n = random(2): height 3 + n * 5, base.smc frame 1 + n
MOUNT = list(range(12, 20))            # Socle.setType(Mountain): height 12 + random(8)


def hex_cmds(frame, base, height, ctrl):
    inst = instance(S_HEX, {S_HEX: frame, base: 1, **ctrl})
    return cmds_inst(with_entry(inst, 'base', dy=-height))


hexes = {
    'hexB': [hex_cmds(1, B_BEACH, 0, {S_TEX: t}) for t in TEX],
    'hexD': [hex_cmds(2, B_DIRT, h, {S_TEX: t, S_ISLE: v}) for h, v in DIRT for t in TEX],
    'hexM': [hex_cmds(3, B_MOUNT, h, {}) for h in MOUNT],
}
masks = {}
for name, lists in hexes.items():
    imgs, reg = render(lists + [(c, HOVER) for c in lists])
    n = len(lists)
    save_anim(name, imgs[:n], reg)
    save_anim(name + 'H', imgs[n:], reg)
    # hit areas: the pixels of the picture at least half covered (Flash tests the shapes of the clip)
    ms = []
    for im in imgs[:n]:
        a = np.asarray(im)[..., 3] >= 128
        ys, xs = np.nonzero(a)
        x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
        rows = []
        for y in range(y0, y1):
            r = a[y, x0:x1].astype(np.int8)
            d = np.diff(np.concatenate([[0], r, [0]]))
            st, en = np.nonzero(d == 1)[0], np.nonzero(d == -1)[0]
            rows.append(','.join('%d-%d' % (s, e) for s, e in zip(st, en)))
        ms.append(dict(x=int(x0 - reg[0]), y=int(y0 - reg[1]), rows=';'.join(rows)))
    masks[name] = ms
meta['masks'] = masks
meta['dirt'] = DIRT
meta['mountMin'] = MOUNT[0]

imgs, reg = render([cmds_of(S_SEL)])
save_anim('sel', imgs, reg)

# soldiers placed by the base timelines: [kind (0 soldier, 1 shadow), x, y, alpha] in depth order, per frame
def base_layout(sid):
    out = []
    for f in range(1, 12):
        inst = instance(sid, {sid: f})
        items = []
        for d in sorted(inst.display):
            e = inst.display[d]
            m = e['matrix']
            if e['inst'] is not None and e['inst'].sid == S_SOLDAT:
                items.append([0, twips(m['tx']), twips(m['ty']), 1])
            elif e['char'] == SH_SHADOW:
                items.append([1, twips(m['tx']), twips(m['ty']), round(e['cx']['mult'][3], 4)])
        assert sum(1 for i in items if i[0] == 0) == f - 1, (sid, f)
        out.append(items)
    return out


meta['bases'] = {'beach': base_layout(B_BEACH), 'dirt': base_layout(B_DIRT), 'mount': base_layout(B_MOUNT)}

# ---------------------------------------------------------------- castle
cinst = instance(S_CASTLE, {S_CASTLE: 1})
for d, e in cinst.display.items():
    if e['name'] == 'base':
        meta['castleBase'] = [twips(e['matrix']['tx']), twips(e['matrix']['ty']), e['matrix']['d']]
imgs, reg = render([cmds_of(S_CASTLE, {S_CASTLE: 1, B_DIRT: 1, S_ISLE: 2, S_TEX: t}) for t in TEX])
save_anim('castle', imgs, reg)

# ---------------------------------------------------------------- soldiers
def soldat(team, smc, extra=None):
    return cmds_of(S_SOLDAT, {S_SOLDAT: team + 1, S_SMC: smc, **(extra or {})})


lists = [soldat(0, 1), soldat(1, 1), (soldat(0, 1), BLINK), (soldat(1, 1), BLINK), soldat(0, 4), soldat(1, 4)]
imgs, reg = render(lists)
save_anim('sold', imgs, reg)
for team in (0, 1):
    imgs, reg = render([soldat(team, 2, {S_DANCE: f}) for f in range(1, 20)])
    save_anim('dance%d' % team, imgs, reg)

# ---------------------------------------------------------------- effects
imgs, reg = render([cmds_of(S_SHADE)])
save_anim('shade', imgs, reg)
# mcRay (frame 9 removes it before it is drawn), mcOnde (frame 22: empty, removes it)
imgs, reg = render([cmds_of(S_RAY, {S_RAY: f}) for f in range(1, 9)])
save_anim('ray', imgs, reg)
imgs, reg = render([cmds_of(S_ONDE, {S_ONDE: f}) for f in range(1, 22)])
save_anim('onde', imgs, reg)
imgs, reg = render([cmds_of(S_DRIP)])
save_anim('drip', imgs, reg)
imgs, reg = render([cmds_of(S_STAR)])
save_anim('star', imgs, reg)

# brushSeaside drawn into the sea bitmap: m.rotate(i * 6.28 / 6); m.scale(1.01, 1.01) (translated by the code),
# random frame, brush.smc._alpha 100 on a beach, 40 otherwise
for key, alpha in (('brushB', 1.0), ('brushD', 0.4)):
    lists = []
    for i in range(6):
        a = i * 6.28 / 6
        c, s = math.cos(a) * 1.01, math.sin(a) * 1.01
        M = dict(a=c, b=s, c=-s, d=c, tx=0.0, ty=0.0)
        for f in range(1, 6):
            lists.append(cmds_inst(with_entry(instance(S_BRUSH, {S_BRUSH: f}), 'smc', alpha=alpha), M))
    imgs, reg = render(lists)
    save_anim(key, imgs, reg)


# ---------------------------------------------------------------- interface: Filt.glow(inter, 2, 1, 0)
def glow_only(blur, strength):
    """the GlowFilter alone (black), as drawn under the clip"""
    def f(canvas):
        g = np.clip(R.box_blur(canvas[..., 3], blur * Z, blur * Z, 1) * strength, 0, 1)
        return np.stack([np.zeros_like(g)] * 3 + [g], axis=-1).astype(np.float32)
    return f


inter = cmds_of(S_INTER)
imgs, reg = render([inter, (inter, glow_only(2, 1))], pad=3)
save_anim('inter', imgs[:1], reg)
save_anim('interG', imgs[1:], reg)

# ---------------------------------------------------------------- digits of the text fields
TX = swftext.all_edittexts(W + 'gfx.swf')
raw = open(W + 'gfx.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
HEADER_END = _hb.pos
TAGS = SD.read_tags(DATA, HEADER_END, len(DATA))


def font_layout(fid):
    for code, body in TAGS:
        if code not in (48, 75) or struct.unpack_from('<H', body, 0)[0] != fid:
            continue
        em = 20480.0 if code == 75 else 1024.0
        _, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
        wide = flags & 0x08
        base = q
        q += ng * (4 if wide else 2)
        q = base + struct.unpack_from('<I' if wide else '<H', body, q)[0]
        codes = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)]
        q += 2 * ng
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        return dict(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})


FONT = font_layout(36)
TTF = W + 'fonts_gfx/36_Impact.ttf'


def field_place(sid, tid):
    for d, e in instance(sid).display.items():
        if e['char'] == tid:
            return e


def solid(rgb, a):
    im = Image.new('RGBA', (a.shape[1], a.shape[0]), tuple(rgb) + (0,))
    im.putalpha(Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8), 'L'))
    return im


def digits(name, sid, tid, glow=None):
    """digits 0-9 of a text field (its colour, the scale of its placement); pivot = pen position on the baseline.
    The filters of the field's placement (GlowFilter, DropShadowFilter, applied one after the other in stage pixels)
    are baked as layers under the glyph, from the bottom: name + '_L0', '_L1'... (the glyph itself is the last one):
    the game draws every glyph's layer 0, then every glyph's layer 1..., as Flash draws the filters of the field
    under its whole text. glow (blur, strength): a black GlowFilter of the clip holding the field (name + 'G', drawn
    under that clip)."""
    t = TX[tid]
    e = field_place(sid, tid)
    m = e['matrix']
    filters = e.get('filters') or []
    sx, sy = m['a'], m['d']
    size = t['height']
    SS = 4
    pad = 8
    font = ImageFont.truetype(TTF, int(round(size * K * SS)))
    w = int(math.ceil(max(FONT['adv'][c] for c in '0123456789') * size * sx * K)) + 2 * pad + 4
    h = int(math.ceil((FONT['ascent'] + FONT['descent']) * size * sy * K)) + 2 * pad + 2
    ox, oy = pad + 1, pad + int(math.ceil(FONT['ascent'] * size * sy * K))
    bw, bh = int(round(w * SS / sx)), int(round(h * SS / sy))
    rgb = tuple(int(t['color'][i:i + 2], 16) for i in (1, 3, 5))
    layers, gls = None, []
    for ch in '0123456789':
        big = Image.new('L', (bw, bh), 0)
        ImageDraw.Draw(big).text((ox * SS / sx, oy * SS / sy), ch, font=font, fill=255, anchor='ls')
        a = np.asarray(big.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0
        # the field's filters, each one on the result of the previous (alpha `ca`): its layer goes under the others
        stack = [(rgb, a)]
        ca = a
        for f in filters:
            if f['type'] == 'glow':
                g = np.clip(R.box_blur(ca, f['blurX'] * K, f['blurY'] * K, f.get('passes', 1)) * f['strength'], 0, 1)
            elif f['type'] == 'dropshadow':
                dx = int(round(f['distance'] * math.cos(f['angle']) * K))
                dy = int(round(f['distance'] * math.sin(f['angle']) * K))
                g = np.roll(np.roll(ca, dy, axis=0), dx, axis=1)
                if f['blurX'] >= 1 or f['blurY'] >= 1:
                    g = R.box_blur(g, f['blurX'] * K, f['blurY'] * K, f.get('passes', 1))
                g = np.clip(g * f['strength'], 0, 1)
            else:
                raise ValueError(f['type'])
            assert not f.get('inner') and not f.get('knockout')
            g = g * (f['color'][3] / 255.0)
            stack.insert(0, (f['color'][:3], g))
            ca = ca + g * (1 - ca)
        if layers is None:
            layers = [[] for _ in stack]
        for k, (c, al) in enumerate(stack):
            layers[k].append(solid(c, al))
        if glow:
            gls.append(solid((0, 0, 0), np.clip(R.box_blur(ca, glow[0] * K, glow[0] * K, 1) * glow[1], 0, 1)))
    for k, ims in enumerate(layers):
        save_anim('%s_L%d' % (name, k), ims, (ox, oy))
    if glow:
        save_anim(name + 'G', gls, (ox, oy))
    b = t['bounds']
    # Flash layout: 2 px gutter, first baseline at top + 2 + ascent (field units), then the placement matrix
    meta[name] = dict(adv=[round(FONT['adv'][c] * size * sx, 4) for c in '0123456789'],
                      x0=round(m['tx'] + (b[0] + 2) * sx, 4), x1=round(m['tx'] + (b[1] - 2) * sx, 4),
                      base=round(m['ty'] + (b[2] + 2 + FONT['ascent'] * size) * sy, 4), align=t['align'],
                      layers=len(layers))
    print(name, meta[name], [f['type'] for f in filters])


digits('digInter0', S_INTER, 49, glow=(2, 1))
digits('digInter1', S_INTER, 50, glow=(2, 1))
digits('digCastle', S_CASTLE, 37)

# ---------------------------------------------------------------- messages: FFDec renders of patched gfx.swf copies
FFDEC = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()


def patched_swf(path, texts):
    """gfx.swf with the initial text of some DefineEditText replaced (cid -> text)"""
    out = bytearray()
    for code, body in TAGS:
        if code == 37:
            cid = struct.unpack_from('<H', body, 0)[0]
            if cid in texts:
                old = TX[cid]['text'].encode('utf-8')
                assert body.endswith(old + b'\0'), cid
                body = body[:len(body) - len(old) - 1] + texts[cid].encode('utf-8') + b'\0'
        if len(body) < 63 and code not in (6, 21, 35, 20, 36, 90):
            out += struct.pack('<H', (code << 6) | len(body))
        else:
            out += struct.pack('<HI', (code << 6) | 63, len(body))
        out += body
    data = bytearray(b'FWS') + DATA[3:4] + b'\0\0\0\0' + DATA[8:HEADER_END] + out
    struct.pack_into('<I', data, 4, len(data))
    open(path, 'wb').write(data)


TMP = os.path.join(W, 'texts')
if os.path.isdir(TMP):
    shutil.rmtree(TMP)
os.makedirs(TMP)
TEXT_BOUNDS = {}
for code, body in TAGS:
    if code in (11, 33):
        TEXT_BOUNDS[struct.unpack_from('<H', body, 0)[0]] = SD.Bits(body, 2).rect()


def ffdec_render(tag, texts, sid):
    swf = os.path.join(TMP, tag + '.swf')
    patched_swf(swf, texts)
    d = os.path.join(TMP, tag)
    subprocess.run(FFDEC + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', str(K), '-selectid', str(sid),
                            '-export', 'sprite', d, swf], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    sub = [x for x in os.listdir(d) if x.startswith('DefineSprite_%d_' % sid) or x == 'DefineSprite_%d' % sid][0]
    return Image.open(os.path.join(d, sub, '1.png')).convert('RGBA')


def sprite_origin(sid):
    """top left of the sprite's bounds (shapes, static texts, text field rectangles): FFDec draws it at (0, 0)"""
    xs, ys = [], []
    for d, e in instance(sid).display.items():
        c = e['char']
        b = G.shapes.get(c) or TEXT_BOUNDS.get(c) or TX[c]['bounds']
        m = e['matrix']
        for px, py in ((b[0], b[2]), (b[1], b[2]), (b[0], b[3]), (b[1], b[3])):
            xs.append(m['a'] * px + m['c'] * py + m['tx'])
            ys.append(m['b'] * px + m['d'] * py + m['ty'])
    return min(xs), min(ys)


# Game.newMsg: field.text = str.toUpperCase(), Filt.glow(msg, 2, 4, 0)
MSGS = ['DERNIER COUP', 'BONUS', '+3000 PTS']
pad = 6
ox, oy = sprite_origin(S_MSG_SMC)
ims = []
for i, s in enumerate(MSGS):
    im = ffdec_render('msg%d' % i, {44: s}, S_MSG_SMC)
    c = Image.new('RGBA', (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
    c.paste(im, (pad, pad))
    ims.append(c)
size = (max(i.width for i in ims), max(i.height for i in ims))
out = []
for c in ims:
    cc = Image.new('RGBA', size, (0, 0, 0, 0))
    cc.paste(c, (0, 0))
    arr = np.asarray(cc, dtype=np.float32) / 255.0
    a = arr[..., 3]
    ga = np.clip(R.box_blur(a, 2 * K, 2 * K, 1) * 4, 0, 1)
    # the glow under the text (black): over it, the text
    rgb = arr[..., :3] * a[..., None]
    oa = a + ga * (1 - a)
    res = np.concatenate([np.where(oa[..., None] > 0, rgb / np.maximum(oa[..., None], 1e-6), 0), oa[..., None]], -1)
    out.append(Image.fromarray(np.clip(res * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA'))
save_anim('msg', out, (pad - ox * K, pad - oy * K))
meta['msgs'] = MSGS
# mcMsg: smc placed at (150, y) on each frame; stop() on frame 10, label "leave" = 11, removeMovieClip on 17
msgy = []
for f in range(1, 18):
    e = instance(S_MSG, {S_MSG: f}).display[1]
    assert twips(e['matrix']['tx']) == 150
    msgy.append(twips(e['matrix']['ty']))
meta['msgY'] = msgy

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:14]:
    print('  %-24s %8d px' % (k, v))
