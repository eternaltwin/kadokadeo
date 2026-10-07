"""Builds the Logico graphics for KadoKadeo from the released SWF (game.swf, which holds gfx.swf).

Logico has no character animation: every picture is rendered at x2 ("simple renders" pipeline) and the code
(Game.hx, Ball.hx) picks them. What Flash composed at run time is computed here:
  - mcBg (cacheAsBitmap): the part of the decor inside the 300 x 300 stage, one opaque picture;
  - mcBall, one frame per colour (smc frame = col + 1): "ball" (2 px per Flash pixel) and "ballP" (half a pixel per
    Flash pixel: what Plasma.drawMc draws into the 150 x 150 bitmap of the plasma, mt.bumdum.Bmp with q = 0.5);
  - Game.ballOver: Filt.glow(root, 8, 2, white, inner) then Filt.glow(root, 2, 4, white), baked: "ballOver";
  - Game.updateCombo: Col.setPercentColor(root, tcoef * 100, white) and Filt.glow(root, c * 30, c, white) with
    c = tcoef^2, at the 12 values tcoef takes (+0.2 * tmod each Flash frame, tmod = 0.4): "ballCombo" (12 per colour);
  - mcBallShadow: "shadow" (drawn at 50 % as a group by the game: blendMode "layer" on the plane);
  - partJunk: its smc (3 shapes, gotoAndStop(random)) coloured by Col.setColor(smc, COLORS[col], -200): "junk"
    (3 per colour); the white copies of smc its timeline places on frames 13 and 14: "junkW";
  - partLight: the 2 frames of its smc (it plays): "light";
  - mcScore: the glyphs of its field (Impact, embedded): "glyph", and the layout of the field.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: logico_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/logico holds game.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'logico', '')
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

# Ball.COLORS
COLORS = [0xFF0000, 0xFF9900, 0xBBFF00, 0x22BBFF, 0xBB44FF, 0xFF44EE, 0x6677CC]
# mt.Timer.tmod of a Flash frame (40 frames/s for Timer.wantedFPS = 32: 0.8, halved by Game.update)
TMOD = 0.8 / 2

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


def inst(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def all_cmds(i, M=R.IDENT, cx=R.NOCX):
    out = []
    RD.collect(i, M, cx, set(), out)
    return out


def entry_cmds(e, M=R.IDENT, cx=R.NOCX):
    """draw commands of one display entry (its filters and blend mode kept)"""
    out = []
    RD._emit(e, R.mat_mul(M, e['matrix']), R.cx_mul(cx, e['cx']), set(), out)
    if e.get('filters') or e.get('blend') not in (None, 'normal', 'layer'):
        return [('layer', out, e.get('filters') or [], e.get('blend'))]
    return out


# blendMode "subtract" (the glow disc of the ball, depth 4 of its smc), which swfrender draws normally: the backdrop
# minus the colour (floor 0), composed like the other separable blend modes: Cs (1 - ab) + Cb (1 - as) + as ab B. The
# ball is cacheAsBitmap: its children blend with its own pictures only (a transparent backdrop around them)
_blend_into = R.blend_into


def blend_into(canvas, layer, blend):
    if blend != 'subtract':
        return _blend_into(canvas, layer, blend)
    la, ca = layer[..., 3:4], canvas[..., 3:4]
    cs = np.where(la > 0, layer[..., :3] / np.maximum(la, 1e-6), 0)
    cb = np.where(ca > 0, canvas[..., :3] / np.maximum(ca, 1e-6), 0)
    rgb = layer[..., :3] * (1 - ca) + canvas[..., :3] * (1 - la) + la * ca * np.maximum(cb - cs, 0)
    canvas[..., 3:4] = ca + la * (1 - ca)
    canvas[..., :3] = rgb


R.blend_into = blend_into


def cxf(mult, add):
    return dict(mult=list(mult), add=list(add))


# ---------------------------------------------------------------- Flash filters (premultiplied arrays at Z)
def blur(a, b, passes=1):
    return R.box_blur(a, b * Z, b * Z, passes)


def inner_glow(canvas, blur_px, strength, col=(1.0, 1.0, 1.0)):
    """GlowFilter inner: the glow colour drawn inside the clip (source-atop), from the blurred inverse alpha"""
    a = canvas[..., 3]
    g = np.clip(blur(1 - a, blur_px) * strength, 0, 1) * a
    out = canvas * (1 - g[..., None])
    for i in range(3):
        out[..., i] += g * col[i]
    return out


def outer_glow(canvas, blur_px, strength, col=(1.0, 1.0, 1.0)):
    """GlowFilter (outer): the blurred alpha of the clip, in the glow colour, under the clip"""
    g = np.clip(blur(canvas[..., 3], blur_px) * strength, 0, 1)
    out = canvas.copy()
    a = canvas[..., 3]
    for i in range(3):
        out[..., i] += g * col[i] * (1 - a)
    out[..., 3] += g * (1 - a)
    return out


def flash_int(v):
    """Std.int of AVM1: towards zero"""
    return int(math.trunc(v))


# ---------------------------------------------------------------- mcBg (stage area only)
bg = inst(G.sid('mcBg'))
bb = Box(0, 0, 300, 300, pad=0)
save_anim('bg', [bb.image(bb.draw(all_cmds(bg))).convert('RGB').convert('RGBA')], bb.reg())

# ---------------------------------------------------------------- mcBall
BALL = G.sid('mcBall')


def ball_cmds(col, cx=R.NOCX):
    return all_cmds(inst(BALL, {'smc': col + 1}), cx=cx)


bnd = [RD.bounds(ball_cmds(c)) for c in range(7)]
x0 = min(b[0] for b in bnd); y0 = min(b[1] for b in bnd)
x1 = max(b[2] for b in bnd); y1 = max(b[3] for b in bnd)
box = Box(x0, y0, x1, y1, pad=1)
save_anim('ball', [box.image(box.draw(ball_cmds(c))) for c in range(7)], box.reg())
# Plasma.drawMc: the ball drawn at 0.5 into the bitmap (pixels of the bitmap)
pbox = Box(x0, y0, x1, y1, res=0.5, pad=2)
save_anim('ballP', [pbox.image(pbox.draw(ball_cmds(c))) for c in range(7)], pbox.reg())

# hit areas (mouse): the shapes of the clip are circles centred on the origin: the radius of their union per colour
smc = inst(BALL).display[1]['inst'].sid
hit = []
for c in range(7):
    i = inst(smc, {smc: c + 1})
    r = 0.0
    for d, e in i.display.items():
        cm = entry_cmds(e)
        bx = RD.bounds(cm)
        # (bounds of the shapes, symmetric within 0.05 px: circles)
        assert abs(bx[0] + bx[2]) < 0.11 and abs(bx[1] + bx[3]) < 0.11 and abs((bx[2] - bx[0]) - (bx[3] - bx[1])) < 0.11, (c, d, bx)
        r = max(r, (bx[2] - bx[0] + bx[3] - bx[1]) / 4)
    hit.append(round(r, 4))
meta['ballHit'] = hit

# Game.ballOver: inner glow (8, 2) then outer glow (2, 4), white
obox = Box(x0, y0, x1, y1, pad=6)
imgs = []
for c in range(7):
    s = obox.draw(ball_cmds(c))
    s = inner_glow(s, 8, 2)
    s = outer_glow(s, 2, 4)
    imgs.append(obox.image(s))
save_anim('ballOver', imgs, obox.reg())

# Game.updateCombo: tcoef = min(tcoef + 0.2 * tmod, 1) from 0; while it is below 1, setPercentColor(root, tcoef * 100,
# white) and, on filters emptied, Filt.glow(root, c * 30, c, white) with c = tcoef^2
steps = []
t = 0.0
while True:
    t = min(t + 0.2 * TMOD, 1)
    if t >= 1:
        break
    steps.append(t)
assert len(steps) == 12, steps
cbox = Box(x0, y0, x1, y1, pad=18)
imgs = []
for c in range(7):
    for t in steps:
        prc = t * 100
        # Col.setPercentColor as compiled: ra = int(100 - prc), rb = int(prc / 100 * 255) (+ inc 0)
        ra = flash_int(100 - prc)
        rb = flash_int(prc / 100 * 255)
        cx = cxf([ra / 100.0] * 3 + [1.0], [rb] * 3 + [0])
        s = cbox.draw(ball_cmds(c, cx))
        k = t ** 2
        s = outer_glow(s, k * 30, k)
        imgs.append(cbox.image(s))
save_anim('ballCombo', imgs, cbox.reg())
meta['comboSteps'] = len(steps)

# ---------------------------------------------------------------- mcBallShadow
sh = inst(G.sid('mcBallShadow'))
cm = all_cmds(sh)
sbox = Box(*RD.bounds(cm), pad=1)
save_anim('shadow', [sbox.image(sbox.draw(cm))], sbox.reg())

# ---------------------------------------------------------------- partJunk
JUNK = G.sid('partJunk')
tl = R.timeline(G, JUNK, 14, ctrl={'__noactions__': True})
d1 = tl[0].display[1]
jsid = d1['inst'].sid
jn = G.sprites[jsid].nframes
assert jn == 3


def junk_smc(f, cx):
    """smc (depth 1, its frame f) under the colour transform cx"""
    i = inst(jsid, {jsid: f})
    e = dict(d1, inst=i)
    return entry_cmds(e, cx=cx)


def junk_white(state, depths):
    """the white copies of smc on a frame of the partJunk timeline"""
    out = []
    for d in depths:
        e = state.display[d]
        out += entry_cmds(e)
    return out


cms = []
for c in range(7):
    col = COLORS[c]
    r, g, b = (col >> 16) & 255, (col >> 8) & 255, col & 255
    # Col.setColor(mc, col, -200) as compiled: multipliers 100, offsets int(channel - 200)
    cx = cxf([1.0, 1.0, 1.0, 1.0], [flash_int(r - 200), flash_int(g - 200), flash_int(b - 200), 0])
    for f in range(1, jn + 1):
        cms.append(junk_smc(f, cx))
# the white copies: frame 13 (d3 new, its frame 1), frame 14 played from 13 (d3 on its frame 2 + d5 new), frame 14
# reached by a goto (gotoAndPlay(14): d3 and d5 new, both on their frame 1)
assert sorted(tl[12].display) == [1, 3] and sorted(tl[13].display) == [1, 3, 5]
st14g = inst(JUNK)
st14g.goto_and_play(14)
wcms = [junk_white(tl[12], [3]), junk_white(tl[13], [3, 5]), junk_white(st14g, [3, 5])]
assert tl[13].display[3]['inst'].frame == 2 and st14g.display[3]['inst'].frame == 1
bx = None
for cm in cms + wcms:
    b = RD.bounds(cm)
    bx = b if bx is None else (min(bx[0], b[0]), min(bx[1], b[1]), max(bx[2], b[2]), max(bx[3], b[3]))
jbox = Box(*bx, pad=1)
save_anim('junk', [jbox.image(jbox.draw(cm)) for cm in cms], jbox.reg())
save_anim('junkW', [jbox.image(jbox.draw(cm)) for cm in wcms], jbox.reg())
meta['junkFrames'] = G.sprites[JUNK].nframes

# ---------------------------------------------------------------- partLight: smc (sprite of 2 frames, playing)
LIGHT = G.sid('partLight')
le = inst(LIGHT).display[1]
lsid = le['inst'].sid
assert le['matrix'] == R.IDENT or (le['matrix']['a'] == 1 and le['matrix']['tx'] == 0)
lcms = [all_cmds(inst(lsid, {lsid: f})) for f in range(1, G.sprites[lsid].nframes + 1)]
bx = RD.bounds(lcms[0])
for cm in lcms[1:]:
    b = RD.bounds(cm)
    bx = (min(bx[0], b[0]), min(bx[1], b[1]), max(bx[2], b[2]), max(bx[3], b[3]))
lbox = Box(*bx, pad=1)
save_anim('light', [lbox.image(lbox.draw(cm)) for cm in lcms], lbox.reg())


# ---------------------------------------------------------------- mcScore: field (Impact, embedded)
def font_layouts(path):
    """DefineFont2 / 3 layouts: font id -> codes, ascent, advances (em fractions)"""
    raw = open(path, 'rb').read()
    data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
    bb = SD.Bits(data, 8); bb.rect(); bb.u16(); bb.u16()
    out = {}
    for code, body in SD.read_tags(data, bb.pos, len(data)):
        if code not in (48, 75):
            continue
        em = 20480.0 if code == 75 else 1024.0
        fid, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
        if ng == 0:
            continue
        wide = flags & 0x08
        wide_codes = code == 75 or (flags & 0x04)
        base = q
        q += ng * (4 if wide else 2)
        cto = struct.unpack_from('<I' if wide else '<H', body, q)[0]
        q = base + cto
        if wide_codes:
            codes = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)]
            q += 2 * ng
        else:
            codes = list(body[q:q + ng])
            q += ng
        assert flags & 0x80, 'font %d without layout' % fid
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        out[fid] = dict(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


TX = swftext.all_edittexts(W + 'game.swf')
SCORE = G.sid('mcScore')
# (the field "field": its instance name is obfuscated in the released SWF)
se = [e for e in inst(SCORE).display.values() if e['char'] in TX][0]
tf = TX[se['char']]
assert tf['useOutlines'] and tf['align'] == 'right'
# its GlowFilter (black, 5, strength 10): computed on the alpha of the whole text; drawn here glyph by glyph (the glow
# of each glyph under all the glyphs: strength 10 saturates it, the union of the glows is the glow of the union)
GF = se['filters']
assert len(GF) == 1 and GF[0]['type'] == 'glow' and not GF[0]['inner'] and GF[0]['passes'] == 1 and GF[0]['blurX'] == GF[0]['blurY']
FL = font_layouts(W + 'game.swf')[tf['font']]
TTF = [os.path.join(W, 'fonts_game', n) for n in os.listdir(W + 'fonts_game') if n.startswith('%d_' % tf['font'])][0]
CHARS = '+0123456789x '
size = tf['height']
SS = 2      # glyphs drawn at Z (= K * SS) pixels per Flash pixel, then reduced
assert K * SS == Z
font = ImageFont.truetype(TTF, int(round(size * Z)))
pad = int(math.ceil(GF[0]['blurX'] / 2 + 1)) * K
gw = int(math.ceil(max(FL['adv'][c] for c in CHARS) * size * K)) + 2 * pad + 8
gh = int(math.ceil((FL['ascent'] + FL['descent']) * size * K)) + 2 * pad + 2
ox, oy = pad + 3, pad + int(math.ceil(FL['ascent'] * size * K))
rgb = tuple(int(tf['color'][i:i + 2], 16) for i in (1, 3, 5))
gcol = GF[0]['color']
imgs, glows = [], []
for ch in CHARS:
    big = Image.new('L', (gw * SS, gh * SS), 0)
    if ch != ' ':
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
    a = np.asarray(big, dtype=np.float32) / 255.0
    al = big.resize((gw, gh), Image.LANCZOS)
    g = Image.new('RGBA', (gw, gh), rgb + (0,))
    g.putalpha(al)
    imgs.append(g)
    ga = np.clip(blur(a, GF[0]['blurX']) * GF[0]['strength'], 0, 1) * (gcol[3] / 255.0)
    gi = Image.fromarray(np.clip(ga * 255 + 0.5, 0, 255).astype(np.uint8), 'L').resize((gw, gh), Image.LANCZOS)
    g = Image.new('RGBA', (gw, gh), tuple(gcol[:3]) + (0,))
    g.putalpha(gi)
    glows.append(g)
save_anim('glyph', imgs, (ox, oy))
save_anim('glyphGlow', glows, (ox, oy))
m = se['matrix']
assert abs(m['a'] - 1) < 3e-3 and abs(m['d'] - 1) < 3e-3 and m['b'] == 0 and m['c'] == 0, m
b = tf['bounds']
# Flash text field layout: 2 px gutter, first baseline = top + 2 + ascent; right aligned on the right gutter
meta['scoreField'] = dict(chars=CHARS, adv=[round(FL['adv'][c] * size, 4) for c in CHARS],
                          right=round(m['tx'] + b[1] - 2, 4), base=round(m['ty'] + b[2] + 2 + FL['ascent'] * size, 4))

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:16]:
    print('  %-24s %8d px' % (k, v))
