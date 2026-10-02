"""Builds the Linea graphics for KadoKadeo from the original SWF (gfx.swf).

Linea has no nested logic: every symbol is rendered at x2 ("simple renders" pipeline) and the code picks frames.
  - mcSquare (4 faces), mcPart, mcSoloBonus and mcBonusParts are rendered from the shapes (FFDec zoom 4, composed
    at x4 then reduced);
  - mcAddline is rendered once per frame of its nested mcAniglow (12 frames, the ring grows, blurs and fades);
    its _width / _height for each of these frames is measured here: the game reads them for its collisions;
  - mcBack is the bitmap of its bitmap fill, at its native resolution (drawn x2 like the zoomed Flash player);
  - the text clips (mcStart, mcUI, mcLineScore, mcBonusScore, mcBonusCombo) are rendered by FFDec from copies of
    gfx.swf whose text fields hold the strings the game writes in them (one copy per value);
  - the filters the code puts on clips (DropShadowFilter of the interface, GlowFilter of the score popups) are
    baked as white silhouettes on the same canvas, tinted by the game with the colour it chose;
  - Col.setColor (a colour offset, not a tint) on the yellow bonus stars and their particles + the GlowFilter of
    the particles cannot be a tint: one baked variant per colour the game can draw (OBJECTS_COLOR).
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: linea_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/linea holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'linea', '')
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


def cmds_of(sid, ctrl=None, cx=R.NOCX):
    inst = R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))
    out = []
    R.Renderer(G, K).collect(inst, R.IDENT, cx, set(), out)
    return out


def render(cmd_lists, pad=0.5, post=None):
    """command lists drawn on one common canvas (x4, reduced to x2); post(canvas) runs at x4 before the reduction
    (filters, colour transforms applied after them). Returns (images, registration in px)."""
    rd = R.Renderer(G, K)
    bb = None
    for cmds in cmd_lists:
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
    for cmds in cmd_lists:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        if post:
            canvas = post(canvas)
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        imgs.append(im.resize((w, h), Image.LANCZOS).convert('RGBA'))
    return imgs, (-ox * K, -oy * K)


def offset_cx(canvas, col):
    """Col.setColor(mc, col): colour offset col - 255 on every channel (multipliers 100 %), on the filtered clip"""
    a = canvas[..., 3:4]
    rgb = np.where(a > 0, canvas[..., :3] / np.maximum(a, 1e-6), 0)
    add = np.array([((col >> 16) & 255) - 255, ((col >> 8) & 255) - 255, (col & 255) - 255], dtype=np.float32) / 255.0
    rgb = np.clip(rgb + add, 0, 1)
    return np.concatenate([rgb * a, a], axis=-1).astype(np.float32)


def glow(canvas, col, blur, strength, z):
    r, g, b = (col >> 16) & 255, (col >> 8) & 255, col & 255
    return R.apply_filter(canvas, dict(type='glow', color=(r, g, b, 255), blurX=blur, blurY=blur, strength=strength, passes=1), z)


def twips_bounds(cmds):
    b = R.Renderer(G, K).bounds(cmds)
    return [round(v * 20) / 20.0 for v in b]


# ---------------------------------------------------------------- colours the game can draw
# Game.addObject / removeBonus: OBJECTS_COLOR[colorTheme][Std.random(DOTCOLORS[colorTheme].length)], at most 4 lines
OBJECTS_COLOR = [
    [(125, 198, 34), (0, 170, 189), (243, 194, 0), (226, 0, 120)],
    [(245, 211, 0), (44, 180, 49), (150, 129, 183), (207, 2, 38)],
    [(191, 177, 211), (187, 219, 136), (249, 244, 0), (191, 2, 34)],
    [(187, 219, 136), (245, 211, 0), (241, 175, 0), (207, 2, 38)],
    [(0, 177, 174), (94, 189, 71), (212, 85, 33), (254, 248, 134)],
    [(112, 199, 212), (255, 213, 114), (250, 114, 54), (205, 208, 10)],
    [(220, 151, 161), (197, 107, 35), (161, 17, 53), (163, 47, 117)],
]
COLORS = sorted({(r << 16) | (g << 8) | b for theme in OBJECTS_COLOR for (r, g, b) in theme})
meta['colors'] = COLORS

# ---------------------------------------------------------------- shapes
sq = [cmds_of(7, {7: f}) for f in (1, 2, 3, 4)]
imgs, reg = render(sq)
save_anim('square', imgs, reg)
meta['squareSize'] = [twips_bounds(c)[2] - twips_bounds(c)[0] for c in sq] + [twips_bounds(c)[3] - twips_bounds(c)[1] for c in sq]
imgs, reg = render([cmds_of(16)])
save_anim('part', imgs, reg)

# mcAddline + the 12 frames of its mcAniglow (looping on its own at 40 frames/s)
al = [cmds_of(56, {54: f}) for f in range(1, 13)]
imgs, reg = render(al, pad=4)
save_anim('addline', imgs, reg)
bb = [twips_bounds(c) for c in al]
meta['addlineW'] = [round(b[2] - b[0], 2) for b in bb]
meta['addlineH'] = [round(b[3] - b[1], 2) for b in bb]

# mcBonus: 4 mcSoloBonus named b1..b4 (placed in this depth order); Col.setColor on mcBonus colours them
stars = []
for d, e in sorted(R.Instance(G, 32, ctrl={'__noactions__': True}).display.items()):
    stars.append([e['name'], e['matrix']['tx'], e['matrix']['ty']])
meta['stars'] = stars
bb = twips_bounds(cmds_of(32))
meta['bonusSize'] = [round(bb[2] - bb[0], 2), round(bb[3] - bb[1], 2)]
star_cmds = []
for c in COLORS:
    add = [((c >> 16) & 255) - 255, ((c >> 8) & 255) - 255, (c & 255) - 255, 0]
    star_cmds.append(cmds_of(31, cx=dict(mult=[1.0, 1.0, 1.0, 1.0], add=add)))
imgs, reg = render(star_cmds)
for c, im in zip(COLORS, imgs):
    save_anim('star%06x' % c, [im], reg)

# mcBonusParts (6 frames): Col.setColor(part, b.color) + GlowFilter() of colour b.color (blur 6, strength 2)
parts = [cmds_of(14, {14: f}) for f in range(1, 7)]
for c in COLORS:
    imgs, reg = render(parts, pad=8, post=lambda cv, c=c: offset_cx(glow(cv, c, 6, 2, Z), c))
    save_anim('bpart%06x' % c, imgs, reg)

# mcBack: its bitmap fill (identity matrix), native resolution
back = Image.open(W + 'img_gfx/49.png').convert('RGBA')
assert G.shapes[50] == [0.0, 600.0, 0.0, 400.0] and back.size == (600, 400)
save_anim('back', [back], (0, 0))
meta['backSize'] = [600, 400]

# a white square: rectangles drawn by the code (borders, interface lines, zone highlights)
save_anim('px', [Image.new('RGBA', (4, 4), (255, 255, 255, 255))], (0, 0))


# interface dots (Game.addDotToUI): drawRectangle(s, 20, 5, fill, 100, line, 100, 1): a fill and a 1 px stroke
def ui_dot():
    S = 8
    w, h = 20, 5
    pad = 1
    big_w, big_h = (w + 2 * pad) * K * S, (h + 2 * pad) * K * S
    u = K * S

    def rect(x0, y0, x1, y1, r=0):
        im = Image.new('L', (big_w, big_h), 0)
        ImageDraw.Draw(im).rounded_rectangle([(x0 + pad) * u, (y0 + pad) * u, (x1 + pad) * u - 1, (y1 + pad) * u - 1], radius=r * u, fill=255)
        return np.asarray(im, dtype=np.float32) / 255.0

    fill = rect(0, 0, w, h)
    line = np.clip(rect(-0.5, -0.5, w + 0.5, h + 0.5, 0.5) - rect(0.5, 0.5, w - 0.5, h - 0.5), 0, 1)
    out = []
    for a in (fill, line):
        im = Image.new('RGBA', (big_w, big_h), (255, 255, 255, 0))
        im.putalpha(Image.fromarray((a * 255 + 0.5).astype(np.uint8), 'L'))
        out.append(im.resize(((w + 2 * pad) * K, (h + 2 * pad) * K), Image.LANCZOS))
    return out, (pad * K, pad * K)


(fill, line), reg = ui_dot()
save_anim('uidotFill', [fill], reg)
save_anim('uidotLine', [line], reg)

# ---------------------------------------------------------------- texts: FFDec renders of patched copies of gfx.swf
FFDEC = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()
TX = swftext.all_edittexts(W + 'gfx.swf')
raw = open(W + 'gfx.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
HEADER_END = _hb.pos
TAGS = SD.read_tags(DATA, HEADER_END, len(DATA))


def html_field(cid, text):
    """the html of a field with its own format and another text (TextField.text keeps the format of the field)"""
    t = TX[cid]['text']
    i, j = t.index('<i>') + 3, t.index('</i>')
    return t[:i] + text + t[j:]


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
FIELDS = (20, 24, 26, 28, 34, 37, 38, 39, 40, 41, 42)


def ffdec_render(tag, texts, sids):
    """renders the sprites `sids` of a patched copy (fields not listed in `texts` keep their text)"""
    swf = os.path.join(TMP, tag + '.swf')
    patched_swf(swf, texts)
    d = os.path.join(TMP, tag)
    subprocess.run(FFDEC + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', str(K), '-selectid',
                            ','.join(str(s) for s in sids), '-export', 'sprite', d, swf],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    out = {}
    for s in sids:
        sub = [x for x in os.listdir(d) if x.startswith('DefineSprite_%d_' % s)][0]
        out[s] = Image.open(os.path.join(d, sub, '1.png')).convert('RGBA')
    return out


TEXT_BOUNDS = {}
for code, body in TAGS:
    if code in (11, 33):
        b = SD.Bits(body, 2)
        TEXT_BOUNDS[struct.unpack_from('<H', body, 0)[0]] = b.rect()


def sprite_origin(sid):
    """top left of the sprite's bounds (shapes, static texts, text field rectangles): FFDec draws it at (0, 0)"""
    xs, ys = [], []
    for d, e in R.Instance(G, sid, ctrl={'__noactions__': True}).display.items():
        c = e['char']
        b = G.shapes.get(c) or G.texts.get(c) or TEXT_BOUNDS.get(c)
        m = e['matrix']
        for px, py in ((b[0], b[2]), (b[1], b[2]), (b[0], b[3]), (b[1], b[3])):
            xs.append(m['a'] * px + m['c'] * py + m['tx'])
            ys.append(m['b'] * px + m['d'] * py + m['ty'])
    return min(xs), min(ys)


def padded(im, sid, pad):
    """image on a canvas grown by `pad` px on each side + registration of the clip origin"""
    ox, oy = sprite_origin(sid)
    c = Image.new('RGBA', (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
    c.paste(im, (pad, pad))
    return c, (pad - ox * K, pad - oy * K)


def alpha_of(im):
    return np.asarray(im, dtype=np.float32)[..., 3] / 255.0


def white(a):
    im = Image.new('RGBA', (a.shape[1], a.shape[0]), (255, 255, 255, 0))
    im.putalpha(Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8), 'L'))
    return im


def drop_shadow(a):
    """DropShadowFilter(2, 45, col, 100, 4, 4): alpha of the shadow alone (drawn under the clip)"""
    d = int(round(2 * math.cos(math.pi / 4) * K))
    s = np.roll(np.roll(a, d, axis=0), d, axis=1)
    return np.clip(R.box_blur(s, 4 * K, 4 * K, 1), 0, 1)


def over(a, b):
    return a + b * (1 - a)


def ui_piece(name, im, two):
    """an interface text with its DropShadowFilter (lineCol) and, when `two`, the second one (darkened colour) that
    shadows the first: images name, name + 'S1', name + 'S2' on one canvas"""
    c, reg = padded(im, 43, 12)
    a = alpha_of(c)
    s1 = drop_shadow(a)
    imgs = [c, white(s1)]
    if two:
        imgs.append(white(drop_shadow(over(a, s1))))
    for i, x in enumerate(imgs):
        save_anim(name + ('', 'S1', 'S2')[i], [x], reg)


empty = {cid: '' for cid in FIELDS}
r = ffdec_render('uiB', {**empty, 37: TX[37]['text']}, [43])
ui_piece('uiB', r[43], False)
r = ffdec_render('uiBottom', {**empty, 38: TX[38]['text'], 39: TX[39]['text'], 40: TX[40]['text']}, [43])
ui_piece('uiBottom', r[43], True)
r = ffdec_render('uiTop', {**empty, 41: TX[41]['text']}, [43])
ui_piece('uiTop', r[43], True)
r = ffdec_render('start', {}, [35])
c, reg = padded(r[35], 35, 0)
save_anim('start', [c], reg)

# values written by the code: dfactor "1".."12" (x-factor = zone bonus 1, 2, 3 or 8 + lines - 1), line score
# "1".."4" (lines - 1), bonus score "2000" with mult "1".."3", combo "12000"
DF_MAX, LINE_MAX, MULT_MAX = 12, 4, 3
dfs, lines, bonus = [], [], []
for n in range(1, DF_MAX + 1):
    texts = {**empty, 42: html_field(42, str(n)), 24: str(n), 28: str(n), 26: '2000', 20: '12000'}
    sids = [43] + ([25] if n <= LINE_MAX else []) + ([29] if n <= MULT_MAX else []) + ([22] if n == 1 else [])
    r = ffdec_render('v%d' % n, texts, sids)
    dfs.append(r[43])
    if 25 in r:
        lines.append(r[25])
    if 29 in r:
        bonus.append(r[29])
    if 22 in r:
        combo = r[22]

cs = [padded(im, 43, 12) for im in dfs]
reg = cs[0][1]
a = [alpha_of(c) for c, _ in cs]
s1 = [drop_shadow(x) for x in a]
save_anim('uiF', [c for c, _ in cs], reg)
save_anim('uiFS1', [white(x) for x in s1], reg)
save_anim('uiFS2', [white(drop_shadow(over(x, y))) for x, y in zip(a, s1)], reg)
meta['dfactorMax'] = DF_MAX


def popup(name, sid, ims):
    """score popup + its GlowFilter(col, 80, 2, 2, 5) (white silhouette, drawn under it)"""
    cs = [padded(im, sid, 8) for im in ims]
    reg = cs[0][1]
    save_anim(name, [c for c, _ in cs], reg)
    save_anim(name + 'G', [white(np.clip(R.box_blur(alpha_of(c), 2 * K, 2 * K, 1) * 5, 0, 1)) for c, _ in cs], reg)


popup('lineScore', 25, lines)
popup('bonusScore', 29, bonus)
popup('bonusCombo', 22, [combo])
meta['lineScoreMax'] = LINE_MAX
meta['multMax'] = MULT_MAX

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:12]:
    print('  %-24s %8d px' % (k, v))
print('meta', json.dumps({k: v for k, v in meta.items() if k != 'colors'}))
