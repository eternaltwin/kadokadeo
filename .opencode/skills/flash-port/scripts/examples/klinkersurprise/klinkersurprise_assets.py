"""Builds the Klinker Surprise graphics for KadoKadeo from the original SWF (gfx.swf).

Klinker Surprise has no nested timeline logic: every picture is rendered at x2 ("simple renders" pipeline), at the
scale the code gives it when that scale is fixed (the zone size of the level: 60, 50 or 40 % for the cells), and the
code places them like the original did.
  - mcGenerator (scale size %): the clip without its smc (frame 1 unlit, frame 2 lit), and the smc alone under
    Col.setColor(smc, COLOR[type]) (multipliers 100 %, offsets colour - 255: not a tint, baked per colour);
  - mcSquare (scale size %, drawn into the ground bitmap by Game.initGround): its smc alone (the code darkens it by a
    random offset per tile: applied at run time on the pixels) and the 7 frames without the smc, on one canvas;
  - mcSelector (the target, scale size %): the 5 frames with the GlowFilter of Game.initStep (blur 10, strength 1,
    white, in stage pixels) baked under them: all white, the code tints frames 2 to 5 (setPercentColor 100);
  - mcSpark (9 frames, scale 20..50 % at run time: rendered at 50 %), mcExplo (drawn into the plasma bitmap with a
    solid colour: white silhouettes at 3 resolutions), mcLight (drawn into the background bitmaps at small scales:
    4 resolutions);
  - mcInter: the time bar (sprite 4, scaled by the code), the glyphs of the embedded Larabiefont (field "LEVEL'nn")
    laid out like Flash at run time; the GlowFilter of the clip is drawn at run time (the bars change every frame).
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: klinkersurprise_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/klinkersurprise holds gfx.swf + exports)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'klinkersurprise', '')
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
S_INTER, S_BAR, S_SELECTOR, S_GEN, S_SQUARE, S_SPARK, S_EXPLO, S_LIGHT = 5, 4, 11, 21, 32, 35, 37, 39
T_FIELD = 2
# Game.COLOR
COLOR = [0xFF0000, 0xFFFF00, 0x00FF00, 0x00FFFF, 0x0000FF, 0xFF00FF, 0xFFAA00, 0xAA00FF]
# Game.LEVEL: the zone sizes
SIZES = [60, 50, 40]


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


def scale(s):
    return dict(a=s, b=0.0, c=0.0, d=s, tx=0.0, ty=0.0)


def cmds_of(sid, ctrl=None, M=R.IDENT, cx=R.NOCX, hide=()):
    out = []
    R.Renderer(G, K).collect(instance(sid, ctrl), M, cx, set(hide), out)
    return out


def cmds_child(sid, name, ctrl=None, M=R.IDENT, cx=None):
    """the named child of a clip alone, in the clip's coordinates; cx: its colour transform set by the code"""
    inst = instance(sid, ctrl)
    rd = R.Renderer(G, K)
    out = []
    for d in sorted(inst.display):
        e = inst.display[d]
        if e['name'] == name:
            rd._emit(e, R.mat_mul(M, e['matrix']), cx if cx is not None else e['cx'], set(), out)
    assert out, (sid, name)
    return out


def render(items, pad=0.5, k=K):
    """items: command lists, or (commands, post) pairs, drawn on one common canvas (x4, reduced to x k);
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
    w, h = int(round((ex - ox) * k)), int(round((ey - oy) * k))
    imgs = []
    for cmds, post in items:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        if post:
            canvas = post(canvas)
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        imgs.append(im.resize((w, h), Image.LANCZOS).convert('RGBA'))
    return imgs, (-ox * k, -oy * k)


def set_color(col, dec=-255):
    """Col.setColor(mc, col, dec): multipliers 100 %, offsets int(channel + dec)"""
    return dict(mult=[1.0, 1.0, 1.0, 1.0], add=[((col >> 16) & 0xFF) + dec, ((col >> 8) & 0xFF) + dec, (col & 0xFF) + dec, 0])


WHITE = dict(mult=[0.0, 0.0, 0.0, 1.0], add=[255, 255, 255, 0])


def glow_under(blur, strength):
    """GlowFilter (outer, quality 1, white) of the clip, in stage pixels, drawn under it"""
    def f(canvas):
        a = canvas[..., 3]
        g = np.clip(R.box_blur(a, blur * Z, blur * Z, 1) * strength, 0, 1)
        out = canvas.copy()
        # white glow under the clip: premultiplied white * g * (1 - a)
        add = (g * (1 - a))[..., None]
        out[..., :3] += add
        out[..., 3:4] += add
        return out
    return f


# ---------------------------------------------------------------- generators (scale size %)
for s in SIZES:
    M = scale(s / 100.0)
    imgs, reg = render([cmds_of(S_GEN, {S_GEN: f}, M, hide=('smc',)) for f in (1, 2)])
    save_anim('gen%d' % s, imgs, reg)
    for f in (1, 2):
        imgs, reg = render([cmds_child(S_GEN, 'smc', {S_GEN: f}, M, set_color(c)) for c in COLOR])
        save_anim('gsm%d_%d' % (s, f), imgs, reg)

# ---------------------------------------------------------------- ground tiles: smc alone + the 7 frames without it
for s in SIZES:
    M = scale(s / 100.0)
    lists = [cmds_child(S_SQUARE, 'smc', {S_SQUARE: 1}, M)] + \
            [cmds_of(S_SQUARE, {S_SQUARE: f}, M, hide=('smc',)) for f in range(1, 8)]
    imgs, reg = render(lists)
    # (the ground is composed on a canvas at integer pixels: the origin of the tile must be on a pixel)
    assert reg[0] == int(reg[0]) and reg[1] == int(reg[1]), reg
    save_anim('sq%d' % s, imgs[:1], reg)
    save_anim('sqo%d' % s, imgs[1:], reg)

# ---------------------------------------------------------------- target: mcSelector + Filt.glow(mcTarget, 10, 1, white)
for s in SIZES:
    M = scale(s / 100.0)
    imgs, reg = render([(cmds_of(S_SELECTOR, {S_SELECTOR: f}, M), glow_under(10, 1)) for f in range(1, 6)], pad=6.5)
    save_anim('sel%d' % s, imgs, reg)

# ---------------------------------------------------------------- particles
# mcSpark: setScale(20 + random * 30) then shrinking: rendered at 50 % (1 texture pixel per Flash pixel)
imgs, reg = render([cmds_of(S_SPARK, {S_SPARK: f}, scale(0.5)) for f in range(1, 10)])
save_anim('spark', imgs, reg)
# mcExplo drawn into the plasma (1 bitmap pixel per Flash pixel) at scale 0.5 .. 4.5 with ColorTransform(0, 0, 0, 1,
# r, g, b, 0): white silhouettes, tinted at run time, at 1, 2 and 4 bitmap pixels per Flash pixel of the clip
for r in (1, 2, 4):
    imgs, reg = render([cmds_of(S_EXPLO, None, scale(r / float(K)), WHITE)], pad=0.5, k=K)
    save_anim('explo%d' % r, imgs, reg)
# mcLight drawn into the background bitmaps (x2 canvas) at scale K * (0.1 .. 0.3) * c, c = 0.2 .. 0.7
for i, r in enumerate((0.0625, 0.125, 0.25, 0.5)):
    imgs, reg = render([cmds_of(S_LIGHT, None, scale(r / K))], pad=1.0)
    save_anim('light%d' % i, imgs, reg)
meta['lightRes'] = [0.0625, 0.125, 0.25, 0.5]

# ---------------------------------------------------------------- interface
imgs, reg = render([cmds_of(S_BAR)], pad=1.0)
save_anim('bar', imgs, reg)
inter = instance(S_INTER)
for d, e in inter.display.items():
    if e['name'] in ('b0', 'b1'):
        m = e['matrix']
        meta[e['name']] = [m['tx'], m['ty'], m['a'], m['d']]

# glyphs of the field (Larabiefont, embedded: L E V ' . 0-9 and the space)
TX = swftext.all_edittexts(W + 'gfx.swf')
raw = open(W + 'gfx.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
TAGS = SD.read_tags(DATA, _hb.pos, len(DATA))


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


t = TX[T_FIELD]
FONT = font_layout(t['font'])
TTF = W + 'fonts_gfx/1_Larabiefont.ttf'
CHARS = "LEV'0123456789"
e = [e for e in inter.display.values() if e['char'] == T_FIELD][0]
m = e['matrix']
sx, sy = m['a'], m['d']
size = t['height']
SS = 4
pad = 4
font = ImageFont.truetype(TTF, int(round(size * K * SS)))
gw = int(math.ceil(max(FONT['adv'][c] for c in CHARS) * size * sx * K)) + 2 * pad + 8
gh = int(math.ceil((FONT['ascent'] + FONT['descent']) * size * sy * K)) + 2 * pad + 4
ox, oy = pad + 1, pad + int(math.ceil(FONT['ascent'] * size * sy * K))
bw, bh = int(round(gw * SS / sx)), int(round(gh * SS / sy))
rgb = tuple(int(t['color'][i:i + 2], 16) for i in (1, 3, 5))
glyphs = []
for ch in CHARS:
    big = Image.new('L', (bw, bh), 0)
    ImageDraw.Draw(big).text((ox * SS / sx, oy * SS / sy), ch, font=font, fill=255, anchor='ls')
    a = big.resize((gw, gh), Image.LANCZOS)
    im = Image.new('RGBA', (gw, gh), rgb + (0,))
    im.putalpha(a)
    glyphs.append(im)
save_anim('glyph', glyphs, (ox, oy))
b = t['bounds']
# Flash layout: 2 px gutter, first baseline at top + 2 + ascent (field units), then the placement matrix
meta['field'] = dict(chars=CHARS, adv=[round(FONT['adv'][c] * size * sx, 4) for c in CHARS],
                     x0=round(m['tx'] + (b[0] + 2) * sx, 4), x1=round(m['tx'] + (b[1] - 2) * sx, 4),
                     base=round(m['ty'] + (b[2] + 2 + FONT['ascent'] * size) * sy, 4), align=t['align'])
print('field', meta['field'])

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k_, v in sorted(area.items(), key=lambda x: -x[1])[:14]:
    print('  %-24s %8d px' % (k_, v))
