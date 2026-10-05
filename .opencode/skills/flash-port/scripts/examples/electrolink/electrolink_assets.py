"""Builds the Electrolink graphics for KadoKadeo from the released SWF (game.swf, which holds gfx.swf).

Electrolink has no character animation: every symbol is rendered at x2 ("simple renders" pipeline) and the code
(Tile.hx, Goal.hx, Bg.hx, Scoring.hx) picks the pictures. What Flash composed at run time is computed here:
  - the pipes of the tiles and the goals hold a nested "color" clip (grey, or a green / blue square pulsing over 80
    frames: morph shapes) masked by the pipe and drawn with blendMode "overlay". Overlay is linear in the colour of
    the square once the backdrop is known: each piece is exported as a picture A (drawn normally) and a picture B
    (drawn with blendMode ADD and tinted with the colour of the frame): A + B x colour is exactly the overlay. The
    colours of the 80 frames of each pulse are read from FFDec renders of the morph sprites (meta.json). The grey
    state (a square with a slight gradient) is baked as is;
  - the filters the code puts on clips (Tile.tileOver GlowFilter, the GlowFilters of Tile.update / Goal.charge) are
    baked as separate layers drawn under the clip, in the stage pixels Flash computes them in;
  - mcBg: the decor with its filters, its 4 electric sparks (a part1 dot moving along a timeline, blendMode
    "overlay" on the decor: one picture per frame of the path and per frame of part1) and the circuit drawn over;
  - part1 (particles): white dot, coloured by the code (tint), exported at the vertical scales the code uses;
  - scoring: the glyphs of the TexasLED font of the text fields (white, the colour and the filters are applied at
    run time when the popup is shown, Scoring.hx) and the static "PTS" text with its filters baked.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: electrolink_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/electrolink holds game.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'electrolink', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'game.swf', W + 'shp4_game', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, K)

pivots = {}
area = {}
meta = {}


# ---------------------------------------------------------------- canvas helpers
def save_anim(name, imgs, reg):
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    w, h = imgs[0].size
    for i, im in enumerate(imgs):
        assert im.size == (w, h), name
        im.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(reg[0] / w, 6), round(reg[1] / h, 6)]
    a = 0
    for im in imgs:
        bb = im.split()[3].getbbox()
        if bb:
            a += (bb[2] - bb[0]) * (bb[3] - bb[1])
    area[name] = a


class Box:
    """a rectangle of world units drawn at Z pixels per unit, reduced to `res` pixels per unit; its origin is on the
    pixel grid of the reduced picture"""

    def __init__(self, x0, y0, x1, y1, res=K, pad=1.0):
        step = 1.0 / res
        self.res = res
        self.ox = math.floor((x0 - pad) / step) * step
        self.oy = math.floor((y0 - pad) / step) * step
        ex = math.ceil((x1 + pad) / step) * step
        ey = math.ceil((y1 + pad) / step) * step
        self.w = int(round((ex - self.ox) * res))
        self.h = int(round((ey - self.oy) * res))
        self.Wz = int(round(self.w / res * Z))
        self.Hz = int(round(self.h / res * Z))

    def canvas(self):
        return np.zeros((self.Hz, self.Wz, 4), dtype=np.float32)

    def draw(self, cmds, canvas=None):
        c = self.canvas() if canvas is None else canvas
        RD.draw(cmds, c, (self.ox, self.oy))
        return c

    def reg(self):
        return (-self.ox * self.res, -self.oy * self.res)

    def image(self, canvas):
        """premultiplied canvas at Z -> straight RGBA picture at res"""
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        return im.resize((self.w, self.h), Image.LANCZOS).convert('RGBA')

    def reduce(self, arr):
        """a float HxW array at Z -> at res"""
        im = Image.fromarray(arr.astype(np.float32), 'F')
        return np.asarray(im.resize((self.w, self.h), Image.LANCZOS), dtype=np.float32)


def union(*boxes):
    xs0, ys0, xs1, ys1 = zip(*boxes)
    return min(xs0), min(ys0), max(xs1), max(ys1)


def bounds(cmds):
    return RD.bounds(cmds)


def inst(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def entry_cmds(e, M=R.IDENT):
    """draw commands of one display entry (its filters applied; blend modes are handled by the callers)"""
    out = []
    RD._emit(e, R.mat_mul(M, e['matrix']), R.cx_mul(R.NOCX, e['cx']), set(), out)
    if e.get('filters'):
        return [('layer', out, e['filters'], None)]
    return out


def depth_cmds(i, depths, M=R.IDENT):
    out = []
    for d in depths:
        out += entry_cmds(i.display[d], M)
    return out


def mat(a=1.0, b=0.0, c=0.0, d=1.0, tx=0.0, ty=0.0):
    return dict(a=a, b=b, c=c, d=d, tx=tx, ty=ty)


def rot_scale(deg, s):
    r = math.radians(deg)
    return mat(math.cos(r) * s, math.sin(r) * s, -math.sin(r) * s, math.cos(r) * s)


def straight(arr):
    """premultiplied RGBA float array -> straight RGBA picture (same size)"""
    a = arr[..., 3:4]
    rgb = np.where(a > 0, arr[..., :3] / np.maximum(a, 1e-6), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), 'RGBA')


def white(alpha):
    """a white picture of the given alpha (float array at the final resolution)"""
    im = Image.new('RGBA', (alpha.shape[1], alpha.shape[0]), (255, 255, 255, 0))
    im.putalpha(Image.fromarray(np.clip(alpha * 255 + 0.5, 0, 255).astype(np.uint8), 'L'))
    return im


def coloured(alpha, col):
    im = Image.new('RGBA', (alpha.shape[1], alpha.shape[0]), ((col >> 16) & 255, (col >> 8) & 255, col & 255, 0))
    im.putalpha(Image.fromarray(np.clip(alpha * 255 + 0.5, 0, 255).astype(np.uint8), 'L'))
    return im


# ---------------------------------------------------------------- Flash blend modes and filters (premultiplied arrays)
def overlay_full(back, layer, mask):
    """layer drawn on back with blendMode "overlay" (W3C / Flash: hard light keyed on the backdrop), masked"""
    ab = back[..., 3:4]
    as_ = layer[..., 3:4]
    cb = np.where(ab > 0, back[..., :3] / np.maximum(ab, 1e-6), 0)
    cs = np.where(as_ > 0, layer[..., :3] / np.maximum(as_, 1e-6), 0)
    B = np.where(cb <= 0.5, 2 * cs * cb, 1 - 2 * (1 - cs) * (1 - cb))
    co = layer[..., :3] * (1 - ab) + back[..., :3] * (1 - as_) + as_ * ab * B
    ao = as_ + ab - as_ * ab
    m = mask[..., None]
    out = back * (1 - m)
    out[..., :3] += m * co
    out[..., 3:4] += m * ao
    return out


def overlay_split(back, cov, mask):
    """the same for a layer of flat colour c and coverage cov: returns (A premultiplied RGBA, Bq RGB) with
    result = A + Bq * c (per channel)"""
    ab = back[..., 3:4]
    as_ = cov[..., None]
    cb = np.where(ab > 0, back[..., :3] / np.maximum(ab, 1e-6), 0)
    P = np.where(cb <= 0.5, 0.0, 2 * cb - 1)
    Q = np.where(cb <= 0.5, 2 * cb, 2 * (1 - cb))
    m = mask[..., None]
    A = back * (1 - m)
    A[..., :3] += m * (back[..., :3] * (1 - as_) + as_ * ab * P)
    A[..., 3:4] += m * (as_ + ab - as_ * ab)
    Bq = m * as_ * (1 - ab + ab * Q)
    return A, Bq


def bq_image(box, Bq):
    """B picture: premultiplied colour Bq, alpha = max channel (blendMode ADD: only the colour counts)"""
    ch = [np.clip(box.reduce(Bq[..., i]), 0, 1) for i in range(3)]
    a = np.maximum(np.maximum(ch[0], ch[1]), ch[2])
    rgb = [np.where(a > 0, c / np.maximum(a, 1e-6), 0) for c in ch]
    out = np.stack(rgb + [a], axis=-1)
    return Image.fromarray(np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA')


def blur(a, b, passes=1, z=Z):
    return R.box_blur(a, b * z, b * z, passes)


def glow_layer(alpha, blur_px, strength, passes=1, z=Z):
    """GlowFilter (outer): the glow alone (alpha), drawn under the clip"""
    return np.clip(blur(alpha, blur_px, passes, z) * strength, 0, 1)


def inner_glow(canvas, blur_px, strength, col=(1.0, 1.0, 1.0), passes=1, z=Z):
    """GlowFilter inner: the glow colour drawn inside the clip (source-atop), from the blurred inverse alpha"""
    a = canvas[..., 3]
    g = np.clip(blur(1 - a, blur_px, passes, z) * strength, 0, 1) * a
    out = canvas * (1 - g[..., None])
    for i in range(3):
        out[..., i] += g * col[i]
    return out


def outer_glow(canvas, blur_px, strength, col=(1.0, 1.0, 1.0), passes=1, z=Z):
    g = glow_layer(canvas[..., 3], blur_px, strength, passes, z)
    out = canvas.copy()
    a = canvas[..., 3:4]
    for i in range(3):
        out[..., i] += g * col[i] * (1 - a[..., 0])
    out[..., 3] += g * (1 - a[..., 0])
    return out


def under(top, result):
    """the layer H such that `top` drawn over H gives `result` (both premultiplied)"""
    a = top[..., 3:4]
    return np.clip(np.where(a < 0.999, (result - top) / np.maximum(1 - a, 1e-6), 0), 0, 1)


# ---------------------------------------------------------------- pulse colours (morph shapes, FFDec renders)
FF = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()
SPR = W + 'spr_morph'
if not os.path.isdir(SPR):
    subprocess.run(FF + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', '1', '-selectid', '46,50', '-export',
                         'sprite', SPR, W + 'game.swf'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def pulse(sid):
    d = [x for x in os.listdir(SPR) if x.startswith('DefineSprite_%d' % sid)][0]
    out = []
    for f in range(1, G.sprites[sid].nframes + 1):
        a = np.asarray(Image.open(os.path.join(SPR, d, '%d.png' % f)).convert('RGBA'))
        c = a[a.shape[0] // 2, a.shape[1] // 2]
        assert c[3] == 255 and (a[3:-3, 3:-3, :3] == c[:3]).all(), (sid, f)
        out.append(int(c[0]) << 16 | int(c[1]) << 8 | int(c[2]))
    return out


# color (51): frame 1 grey (shape 42), frame 2 the green pulse (sprite 46), frame 3 the blue pulse (sprite 50)
meta['pulseGreen'] = pulse(46)
meta['pulseBlue'] = pulse(50)
assert len(meta['pulseGreen']) == len(meta['pulseBlue']) == 80


# ---------------------------------------------------------------- pieces with an overlaid "color" clip
def overlay_piece(name, sid, frame, base_depths, mask_depth, color_depth, res=K):
    """pictures name + 'Grey' (color frame 1), name + 'A' / name + 'B' (color frames 2 and 3), alpha of the piece
    (premultiplied canvas at Z of the grey state, for the filters) and its box"""
    i = inst(sid)
    i.goto_and_stop(frame)
    base = depth_cmds(i, base_depths)
    maskc = depth_cmds(i, [mask_depth])
    grey = depth_cmds(i, [color_depth])        # the color clip on its frame 1 (shape 42)
    box = Box(*union(bounds(base), bounds(maskc)), res=res, pad=1.0)
    back = box.draw(base)
    m = np.clip(box.draw(maskc)[..., 3], 0, 1)
    layer = box.draw(grey)
    g = overlay_full(back, layer, m)
    A, Bq = overlay_split(back, np.clip(layer[..., 3], 0, 1), m)
    save_anim(name + 'Grey', [box.image(g)], box.reg())
    save_anim(name + 'A', [box.image(A)], box.reg())
    save_anim(name + 'B', [bq_image(box, Bq)], box.reg())
    return g, box


# tile (66): bg (65, shape 8) + shapes (64) whose frame is the kind of tile (code: mc.smc.gotoAndStop(t + 1))
tb = inst(66)
bg_cmds = entry_cmds(tb.display[1])
bbox = Box(*bounds(bg_cmds), pad=0.5)
save_anim('tileBg', [bbox.image(bbox.draw(bg_cmds))], bbox.reg())
# hit area of the tile buttons: the square of shape 8 (the pipes are inside it)
assert tb.display[1]['matrix'] == R.IDENT or tb.display[1]['matrix']['tx'] == 0
meta['tileHit'] = G.shapes[8]
tile_canvas = {}
for t in range(1, 6):
    # shapes: d1 the pipe, d3 its light, d4 the mask (clipDepth 8), d6 the color clip (overlay)
    g, box = overlay_piece('shape%d' % t, 64, t, [1, 3], 4, 6)
    tile_canvas[t] = (g, box)
    # Tile.update (Charge): Filt.glow(m, 10, 2, white) then Filt.glow(m, 2, 2, white, true) on mc.smc: the outer
    # glow, then an inner glow computed on the result (its alpha includes the outer glow). Baked as one layer drawn
    # under the shapes (the pipes themselves do not change)
    hb = Box(box.ox + 1 / K, box.oy + 1 / K, box.ox + box.w / K, box.oy + box.h / K, pad=8)
    # (the grey composite is enough: the alpha of the piece is the same in the 3 states)
    i = inst(64)
    i.goto_and_stop(t)
    back = hb.draw(depth_cmds(i, [1, 3]))
    m = np.clip(hb.draw(depth_cmds(i, [4]))[..., 3], 0, 1)
    layer = hb.draw(depth_cmds(i, [6]))
    s0 = overlay_full(back, layer, m)
    s1 = outer_glow(s0, 10, 2)
    s2 = inner_glow(s1, 2, 2)
    save_anim('halo%d' % t, [hb.image(under(s0, s2))], hb.reg())

# Tile.tileOver: GlowFilter(0x2E95C0, alpha 1.8 (clamped to 1), blur 10, strength 0.9) on the tile, kept while it
# rotates (scale 120 %, Tile.update: 0, 43.2 and 86.4 degrees after the press, then 90 = 0). Filters are computed in
# stage pixels on the transformed clip: one picture per rotation, in stage orientation (Tile.hx counter-rotates it)
tile_all = entry_cmds(tb.display[1]) + entry_cmds(tb.display[3])
HOVER = [(0, 1.0), (0, 1.2), (43.2, 1.2), (86.4, 1.2)]
for k, (deg, s) in enumerate(HOVER):
    M = rot_scale(deg, s)
    cm = []
    for e in (tb.display[1], tb.display[3]):
        cm += entry_cmds(e, M)
    b = Box(*bounds(cm), pad=8)
    a = np.clip(b.draw(cm)[..., 3], 0, 1)
    gl = glow_layer(a, 10, 0.9)
    save_anim('hover%d' % k, [coloured(np.clip(b.reduce(gl), 0, 1), 0x2E95C0)], b.reg())
meta['hover'] = HOVER

# goal (75): d2 the plug, d3 connect, d6 the mask (clipDepth 9), d7 the color clip (overlay, scaled 1.63 x)
# Goal: mc._xscale = 70 (-70 on the left), mc._yscale = 70: drawn at 1.4 texture pixels per unit, 1:1 on screen
GRES = K * 0.7
g, box = overlay_piece('goal', 75, 1, [2, 3], 6, 7, res=GRES)
# Goal.charge: Filt.glow(mc, 10, 2, white): 10 stage pixels = 10 / 0.7 units of the goal
i = inst(75)
gb_ = Box(box.ox + 1 / GRES, box.oy + 1 / GRES, box.ox + box.w / GRES, box.oy + box.h / GRES, res=GRES, pad=10)
back = gb_.draw(depth_cmds(i, [2, 3]))
m = np.clip(gb_.draw(depth_cmds(i, [6]))[..., 3], 0, 1)
s0 = overlay_full(back, gb_.draw(depth_cmds(i, [7])), m)
gl = glow_layer(s0[..., 3], 10 / 0.7, 2)
save_anim('goalGlow', [white(np.clip(gb_.reduce(gl), 0, 1))], gb_.reg())
meta['goalRes'] = GRES

# ---------------------------------------------------------------- time line
tl = inst(70)
c = entry_cmds(tl.display[2])
b = Box(*bounds(c), pad=0.5)
save_anim('timeLine', [b.image(b.draw(c))], b.reg())
c = depth_cmds(inst(68), [2])
b = Box(*bounds(c), pad=0.0)
save_anim('timeLeft', [b.image(b.draw(c))], b.reg())
# Game.updateTime reads mcTime._timeLeft._width (200 at 100 %) and _height
meta['timeLeft'] = [G.shapes[67][1] - G.shapes[67][0], G.shapes[67][3] - G.shapes[67][2]]
assert tl.display[3]['matrix']['tx'] == 0 and tl.display[3]['matrix']['ty'] == 0

# ---------------------------------------------------------------- particles (part1: 2 frames looping)
# Code scales: 40 (time, rotation), 20 / 30 / 40 / 50 (Game.parts) in y; x shrinks from 100 % (Phys fadeType 5):
# one picture per vertical scale, 100 % wide
PART_SY = [20, 30, 40, 50]
for sy in PART_SY:
    cm = [depth_cmds(inst(27, {27: f}), [1], mat(1, 0, 0, sy / 100.0)) for f in (1, 2)]
    b = Box(*union(bounds(cm[0]), bounds(cm[1])), pad=0.5)
    save_anim('part%d' % sy, [b.image(b.draw(x)) for x in cm], b.reg())
meta['partScales'] = PART_SY

# ---------------------------------------------------------------- mcBg
bgi = inst(38)
# d1 the board, d2 the circuit (GlowFilter + DropShadowFilter), d24..d30 the sparks, d33 the circuit drawn over
base_cmds = depth_cmds(bgi, [1, 2])
SB = Box(0, 0, 300, 300, pad=0.0)
bgc = SB.draw(base_cmds)
assert bgc[..., 3].min() > 0.999, 'mcBg is not opaque'
save_anim('bg', [SB.image(bgc)], SB.reg())
top = depth_cmds(bgi, [33])
b = Box(*bounds(top), pad=0.5)
b = Box(max(b.ox, 0), max(b.oy, 0), min(b.ox + b.w / K, 300), min(b.oy + b.h / K, 300), pad=0.0)
save_anim('bgTop', [b.image(b.draw(top))], b.reg())

# the sparks: controller (32 / 34 / 36) -> anim (28 / 33 / 35, stop() on its frame 1) -> part1 (overlay)
# frame scripts of the controllers: every frame, `random(n) + base == base + 1` plays the anim (Bg.hx)
SPARK_RULE = {32: 200, 34: 100, 36: 100}
sparks = []
for d in (24, 26, 28, 30):
    e = bgi.display[d]
    ctrl = e['inst']
    M1 = R.mat_mul(R.IDENT, e['matrix'])
    ae = ctrl.display[1]
    anim_sid = ae['inst'].sid
    M2 = R.mat_mul(M1, ae['matrix'])
    n = G.sprites[anim_sid].nframes
    ai = inst(anim_sid)
    frames = []
    for f in range(1, n + 1):
        ai.goto_and_stop(f)
        pe = ai.display[1]
        assert pe['blend'] == 'overlay' and pe['inst'].sid == 27
        frames.append(R.mat_mul(M2, pe['matrix']))
    imgs = []
    for f in range(n):
        for p in (1, 2):
            # part1: frame 1 shape 25, frame 2 shape 26 (same depth, same matrix)
            cm = [('shape', 25 if p == 1 else 26, frames[f], R.NOCX)]
            full = Image.new('RGBA', (SB.w, SB.h), (0, 0, 0, 0))
            bb = bounds(cm)
            x0, y0 = max(0, math.floor(bb[0] - 1)), max(0, math.floor(bb[1] - 1))
            x1, y1 = min(300, math.ceil(bb[2] + 1)), min(300, math.ceil(bb[3] + 1))
            if x1 > x0 and y1 > y0:
                sub = Box(x0, y0, x1, y1, pad=0.0)
                lay = sub.draw(cm)
                a = np.clip(lay[..., 3], 0, 1)
                cs = np.where(a[..., None] > 0, lay[..., :3] / np.maximum(a[..., None], 1e-6), 0)
                cb = bgc[y0 * Z:y0 * Z + sub.Hz, x0 * Z:x0 * Z + sub.Wz, :3]
                Bv = np.where(cb <= 0.5, 2 * cs * cb, 1 - 2 * (1 - cs) * (1 - cb))
                # decor opaque: drawn over it, (Bv, alpha a) gives decor * (1 - a) + a * overlay
                patch = np.concatenate([Bv * a[..., None], a[..., None]], axis=-1)
                full.paste(sub.image(patch), (x0 * K, y0 * K))
            imgs.append(full)
    name = 'spark%d' % len(sparks)
    save_anim(name, imgs, SB.reg())
    sparks.append(dict(anim=name, frames=n, odds=SPARK_RULE[ctrl.sid]))
meta['sparks'] = sparks

# ---------------------------------------------------------------- scoring
# scoring (16): _t (smc, 14) slides in and out (x, alpha and a horizontal BlurFilter per frame); _t holds the text
# fields _pts (10, right aligned) and _mult (13, left aligned) in TexasLED 40 and the static text "PTS" (12)
sc = G.sprites[16]
tx, al, bx = [], [], []
cur = dict(tx=0.0, a=1.0, b=0.0)
for f in range(sc.nframes):
    for k_, v in sc.frames[f]:
        if k_ == 'place' and v['depth'] == 1:
            if 'matrix' in v:
                cur['tx'] = v['matrix']['tx']
                assert v['matrix']['ty'] == 0 and v['matrix']['a'] == 1
            if 'cx' in v:
                cur['a'] = v['cx']['mult'][3]
            if 'filters' in v:
                cur['b'] = v['filters'][0]['blurX'] if v['filters'] else 0.0
    tx.append(round(cur['tx'], 2))
    al.append(round(cur['a'], 6))
    bx.append(round(cur['b'], 4))
meta['scoring'] = dict(tx=tx, alpha=al, blur=bx)

TX = swftext.all_edittexts(W + 'game.swf')
raw = open(W + 'game.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
TAGS = SD.read_tags(DATA, _hb.pos, len(DATA))


def font_info(fid):
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
        cto = struct.unpack_from('<I' if wide else '<H', body, q)[0]
        q = base + cto
        wc = code == 75 or (flags & 0x04)
        codes = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)] if wc else list(body[q:q + ng])
        q += (2 if wc else 1) * ng
        out = dict(codes=codes, em=em)
        if flags & 0x80:
            asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
            adv = struct.unpack_from('<%dh' % ng, body, q)
            out.update(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
        return out


def static_text(cid):
    for code, body in TAGS:
        if code in (11, 33) and struct.unpack_from('<H', body, 0)[0] == cid:
            bb = SD.Bits(body, 2)
            bb.rect()
            m = bb.matrix()
            gbits, abits = body[bb.pos], body[bb.pos + 1]
            p = bb.pos + 2
            recs = []
            font = h = None
            x = y = 0.0
            while body[p] != 0:
                fl = body[p]; p += 1
                if fl & 8:
                    font = struct.unpack_from('<H', body, p)[0]; p += 2
                if fl & 4:
                    p += 4 if code == 33 else 3
                if fl & 1:
                    x = struct.unpack_from('<h', body, p)[0] / 20.0; p += 2
                if fl & 2:
                    y = struct.unpack_from('<h', body, p)[0] / 20.0; p += 2
                if fl & 8:
                    h = struct.unpack_from('<H', body, p)[0] / 20.0; p += 2
                n = body[p]; p += 1
                g = SD.Bits(body, p)
                for _ in range(n):
                    gi, adv = g.ub(gbits), g.sb(abits) / 20.0
                    recs.append(dict(font=font, h=h, x=m['tx'] + x, y=m['ty'] + y, glyph=gi))
                    x += adv
                g.align()
                p = g.pos
            return recs


SS = 4
TTF = {3: W + 'fonts_game/3_TexasLED_Texas LED.ttf', 11: W + 'fonts_game/11_TAHOMA.ttf'}


def glyph_alpha(fid, ch, size, pen_x, pen_y, box):
    """alpha of a glyph whose pen is at (pen_x, pen_y) (world units), on the canvas of `box` at Z"""
    font = ImageFont.truetype(TTF[fid], int(round(size * Z)))
    im = Image.new('L', (box.Wz, box.Hz), 0)
    ImageDraw.Draw(im).text(((pen_x - box.ox) * Z, (pen_y - box.oy) * Z), ch, font=font, fill=255, anchor='ls')
    return np.asarray(im, dtype=np.float32) / 255.0


# TexasLED glyphs used by the code: digits and "x" (white, alpha only: Scoring.hx applies the colour and filters)
TL = font_info(3)
size = TX[10]['height']
assert TX[13]['height'] == size and TX[10]['font'] == TX[13]['font'] == 3
CHARS = '0123456789x'
gb = Box(-2, -TL['ascent'] * size - 2, max(TL['adv'][c] for c in CHARS) * size + 2, 0.3 * size, pad=0)
imgs = []
for ch in CHARS:
    a = glyph_alpha(3, ch, size, 0, 0, gb)
    imgs.append(white(np.clip(gb.reduce(a), 0, 1)))
save_anim('glyph', imgs, gb.reg())
smc = inst(14)
fields = {}
for d, e in smc.display.items():
    if e['name'] in ('_pts', '_mult'):
        t = TX[e['char']]
        b = t['bounds']
        fields[e['name']] = dict(x=e['matrix']['tx'] + b[0], y=e['matrix']['ty'] + b[2], w=b[1] - b[0],
                                 align=t['align'], color=int(t['color'][1:], 16),
                                 filters=e['filters'])
meta['text'] = dict(chars=CHARS, adv=[round(TL['adv'][c] * size, 4) for c in CHARS],
                    ascent=round(TL['ascent'] * size, 4), fields=fields)

# "PTS" (static text 12, Tahoma 18) with its GlowFilter + DropShadowFilter, baked in the coordinates of _t
pe = [e for e in smc.display.values() if e['char'] == 12][0]
F11 = font_info(11)
recs = static_text(12)
pb = Box(pe['matrix']['tx'] + 66, pe['matrix']['ty'] - 4, pe['matrix']['tx'] + 120, pe['matrix']['ty'] + 26, pad=0)
a = np.zeros((pb.Hz, pb.Wz), dtype=np.float32)
for r in recs:
    ch = chr(F11['codes'][r['glyph']])
    a = np.maximum(a, glyph_alpha(11, ch, r['h'], pe['matrix']['tx'] + r['x'], pe['matrix']['ty'] + r['y'], pb))
col = TX[10]['color']
rgb = np.array([int(col[1:3], 16), int(col[3:5], 16), int(col[5:7], 16)], dtype=np.float32) / 255.0
lay = np.concatenate([a[..., None] * rgb, a[..., None]], axis=-1)
for f in pe['filters']:
    lay = R.apply_filter(lay, f, Z)
save_anim('ptsLabel', [pb.image(lay)], pb.reg())
meta['ptsFilters'] = pe['filters']

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:16]:
    print('  %-24s %8d px' % (k, v))
