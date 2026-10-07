"""Builds the Hypercube graphics for KadoKadeo from the original SWF.

The released kubik.swf holds gfx.swf with obfuscated export and instance names; its symbols are the same as the
archive's gfx.swf (same ids, same timelines, same shapes: only an unused background sprite 82 is missing), so the
pictures are rendered from gfx.swf, whose names are readable.

Hypercube has no character animation: every symbol is rendered at x2 ("simple renders" pipeline) and the code
(Game.hx, Piece.hx, MC.hx) picks the pictures and plays the few timelines from tables:
  - bg: the decor (a 300 x 300 bitmap) and ray (the stripes of the conveyor: a 20 x 20 bitmap repeated), at their
    native resolution; horloge.ha: the time ring (166 frames: wedges under a rotating mask), flattened per frame at
    the scale of horloge (0.9);
  - cube: the 16 pictures of its sub (one per set of neighbours) under the colour transforms of the cube's frames 1-3
    (not tints: baked), the light of the special cubes (cubLight: frames 4-6, its blinking nested clip) and white
    silhouettes of the sub (Cs.setPercentColor whitens the cube: a tint and an additive white picture, MC.hx);
  - particles (partLight, partQueue), the ring shown where a piece is put (partRound: morph shapes under a mask,
    taken from FFDec renders), the dotted square of the score (scoreSquare.bg) at 2 resolutions;
  - texts: the digits of the score field (Arcade Classic, embedded), "Terminer la partie" (static text, embedded
    glyphs) and the BICOLOR / MONOCOLOR panels of mcScore. Those 2 fields use Arcade Classic as a *device* font
    (useOutlines off, the embedded font has no letter of them): on a computer without that font Flash drew them with
    its default serif font, Times New Roman, as here.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: hypercube_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/hypercube holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'hypercube', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, K)
# zoom 1 export: bitmap fills at their native resolution
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)

pivots = {}
area = {}
meta = {}


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
        im = Image.fromarray(arr.astype(np.float32), 'F')
        return np.asarray(im.resize((self.w, self.h), Image.LANCZOS), dtype=np.float32)


def union(*boxes):
    xs0, ys0, xs1, ys1 = zip(*boxes)
    return min(xs0), min(ys0), max(xs1), max(ys1)


def bounds(cmds):
    return RD.bounds(cmds)


def inst(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def entry_cmds(e, M=R.IDENT, cx=R.NOCX):
    out = []
    RD._emit(e, R.mat_mul(M, e['matrix']), R.cx_mul(cx, e['cx']), set(), out)
    return out


def depth_cmds(i, depths, M=R.IDENT, cx=R.NOCX):
    out = []
    for d in depths:
        out += entry_cmds(i.display[d], M, cx)
    return out


def mat(a=1.0, b=0.0, c=0.0, d=1.0, tx=0.0, ty=0.0):
    return dict(a=a, b=b, c=c, d=d, tx=tx, ty=ty)


def white(alpha):
    im = Image.new('RGBA', (alpha.shape[1], alpha.shape[0]), (255, 255, 255, 0))
    im.putalpha(Image.fromarray(np.clip(alpha * 255 + 0.5, 0, 255).astype(np.uint8), 'L'))
    return im


def alpha8(m):
    """an alpha multiplier of a timeline (8.8 fixed point in the SWF) as Flash's _alpha (percent)"""
    return round(m * 256) / 2.56


# ---------------------------------------------------------------- bg (76): decor, ray, horloge
bgi = inst(76)
e64, eray, ehor = bgi.display[1], bgi.display[2], bgi.display[4]
assert e64['char'] == 64 and eray['name'] == 'ray' and ehor['name'] == 'horloge'
# the decor: a 300 x 300 bitmap fill, native resolution (1 texture pixel per Flash pixel)
im = Image.open(W + 'shp1_gfx/64.png').convert('RGBA')
assert im.size == (300, 300), im.size
save_anim('bg', [im], (0, 0))
# ray (67): shape 66, the 20 x 20 stripes bitmap repeated over 320 x 64, native resolution
im = Image.open(W + 'shp1_gfx/66.png').convert('RGBA')
assert im.size == (320, 64), im.size
assert inst(67).display[1]['matrix'] == R.IDENT
save_anim('ray', [im], (0, 0))
meta['ray'] = dict(x=eray['matrix']['tx'], y=eray['matrix']['ty'], alpha=alpha8(eray['cx']['mult'][3]))
# horloge (75) at 0.9: its ha (74) is drawn at 1.8 texture pixels per unit (1:1 on the screen)
hm = ehor['matrix']
assert abs(hm['a'] - 0.9) < 1e-4 and hm['d'] == hm['a'] and hm['b'] == 0 and hm['c'] == 0
HRES = K * hm['a']
assert inst(75).display[1]['name'] == 'ha' and inst(75).display[1]['matrix'] == R.IDENT
ha = inst(74)
n = G.sprites[74].nframes
hb = Box(-27, -27, 27, 27, res=HRES, pad=0.5)
imgs = []
for f in range(1, n + 1):
    ha.goto_and_stop(f)
    cm = []
    RD.collect(ha, R.IDENT, R.NOCX, set(), cm)
    imgs.append(hb.image(hb.draw(cm)))
save_anim('ha', imgs, hb.reg())
meta['horloge'] = dict(x=hm['tx'], y=hm['ty'], scale=hm['a'] * 100, alpha=alpha8(ehor['cx']['mult'][3]), res=HRES)

# ---------------------------------------------------------------- cube (60)
# frame f (n + 1): sub (57, frame s = 1 + neighbours) under the colour transform of the frame; frames 4-6: the same
# colours as 1-3 (checked below) with cubLight (40) over it
ci = inst(60)
esub = ci.display[1]
assert esub['name'] == 'sub'
SUBN = 16
cb = Box(-7.5, -15, 7.5, 7.5, pad=0.5)
subs = {}
for f in range(1, 7):
    ci.goto_and_stop(f)
    imgs = []
    for s in range(1, SUBN + 1):
        i = inst(60, {57: s})
        i.goto_and_stop(f)
        imgs.append(np.asarray(cb.image(cb.draw(depth_cmds(i, [1])))))
    subs[f] = imgs
for f in (4, 5, 6):
    for s in range(SUBN):
        d = np.abs(subs[f][s].astype(int) - subs[f - 3][s].astype(int)).max()
        assert d <= 1, ('cube frame %d differs from %d' % (f, f - 3), s, d)
for c in range(3):
    save_anim('cube%d' % c, [Image.fromarray(a) for a in subs[c + 1]], cb.reg())
# white silhouettes of the sub (whitening of Cs.setPercentColor: the light of frames 4-6 lies inside the sub)
imgs = []
for s in range(1, SUBN + 1):
    i = inst(60, {57: s})
    a = np.clip(cb.draw(depth_cmds(i, [1]))[..., 3], 0, 1)
    imgs.append(white(np.clip(cb.reduce(a), 0, 1)))
save_anim('cubeW', imgs, cb.reg())
# hit area of the cube buttons: the bounds of the sub's shape for each frame (rectangles), in the cube's coordinates
hits = []
for s in range(1, SUBN + 1):
    i = inst(57)
    i.goto_and_stop(s)
    e = i.display[1]
    x0, x1, y0, y1 = G.shapes[e['char']]
    hits.append([x0 - 7.5, x1 - 7.5, y0 - 15, y1 - 15])
meta['cubeHit'] = hits
# cubLight (40): shape 36 masks its nested 39 (2 frames, looping), placed at (-0.05, 0) on frames 4-6
ci.goto_and_stop(4)
el = ci.display[3]
assert el['char'] == 40
lb = Box(-8, -10, 8.5, 3, pad=0.5)
imgs = []
for b in (1, 2):
    i = inst(40, {39: b})
    cm = []
    RD.collect(i, R.IDENT, R.NOCX, set(), cm)
    imgs.append(lb.image(lb.draw(cm)))
save_anim('cubLight', imgs, lb.reg())
meta['cubLight'] = dict(x=el['matrix']['tx'], y=el['matrix']['ty'])

# ---------------------------------------------------------------- butExt (35): the hit area added to the cubes of
# the conveyor (alpha 0: never drawn)
meta['butExt'] = G.shapes[inst(35).display[1]['char']]

# ---------------------------------------------------------------- particles
# partLight (33): shape 32 at depth 2 (3 frames, the same picture); scaled 50 to 200 % by the code: 4 px per unit
pi = inst(33)
c = depth_cmds(pi, [2])
b = Box(*bounds(c), res=2 * K, pad=0.5)
save_anim('partLight', [b.image(b.draw(c))], b.reg())
# partQueue (22): the line (21: shape 20, 100 x 3) fading out over 21 frames; frame 21: t = 0 (Game.updateParts
# removes it); the code scales it to the distance moved and turns it
qi = inst(22)
c = depth_cmds(qi, [1])
b = Box(*bounds(c), pad=0.5)
save_anim('partQueue', [b.image(b.draw(c))], b.reg())
al = []
for f in range(1, G.sprites[22].nframes + 1):
    qi.goto_and_stop(f)
    al.append(alpha8(qi.display[1]['cx']['mult'][3]))
meta['queueAlpha'] = al
# partRound (5): the grid (shape 1) masks a ring growing (morph shapes 2 and 3): FFDec renders of the sprite (zoom 4,
# its origin is the corner of the union of its shapes); frame 12 removes the clip (removeMovieClip(""))
SPR = W + 'spr4_5'
if not os.path.isdir(SPR):
    FF = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()
    subprocess.run(FF + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', str(Z), '-selectid', '5', '-export',
                         'sprite', SPR, W + 'gfx.swf'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
d = os.path.join(SPR, [x for x in os.listdir(SPR) if x.startswith('DefineSprite_5_')][0])
x0 = min(G.shapes[c][0] for c in (1, 2, 3))
y0 = min(G.shapes[c][2] for c in (1, 2, 3))
n = G.sprites[5].nframes
imgs = []
for f in range(1, n):
    big = Image.open(os.path.join(d, '%d.png' % f)).convert('RGBa')
    imgs.append(big.resize((big.width * K // Z, big.height * K // Z), Image.LANCZOS).convert('RGBA'))
save_anim('partRound', imgs, (-x0 * K, -y0 * K))
meta['roundFrames'] = n

# ---------------------------------------------------------------- scoreSquare (31): bg (28: the dotted square, 104 x
# 104, scaled max * 15 % by the code) and sf (30: the score field)
si = inst(31)
ebg, esf = si.display[1], si.display[3]
assert ebg['name'] == 'bg' and esf['name'] == 'sf'
c = entry_cmds(ebg)
# 2 resolutions: up to 100 % (squares of 3 to 6 cubes) and up to 210 % (14 cubes)
SQ_BIG = 2.1
for name, res in (('squareBg', K), ('squareBgBig', K * SQ_BIG)):
    b = Box(*bounds(c), res=res, pad=0.5)
    save_anim(name, [b.image(b.draw(c))], b.reg())
meta['square'] = dict(bgx=ebg['matrix']['tx'], bgy=ebg['matrix']['ty'], big=SQ_BIG * 100)

# ---------------------------------------------------------------- fonts
raw = open(W + 'gfx.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
TAGS = SD.read_tags(DATA, _hb.pos, len(DATA))
TX = swftext.all_edittexts(W + 'gfx.swf')


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
        assert flags & 0x80
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        out.update(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
        return out


def static_text(cid):
    """records of a DefineText: glyphs with their font, height, colour and pen position (in the text's space)"""
    for code, body in TAGS:
        if code in (11, 33) and struct.unpack_from('<H', body, 0)[0] == cid:
            bb = SD.Bits(body, 2)
            rect = bb.rect()
            m = bb.matrix()
            gbits, abits = body[bb.pos], body[bb.pos + 1]
            p = bb.pos + 2
            recs = []
            font = h = col = None
            x = y = 0.0
            while body[p] != 0:
                fl = body[p]; p += 1
                if fl & 8:
                    font = struct.unpack_from('<H', body, p)[0]; p += 2
                if fl & 4:
                    col = tuple(body[p:p + (4 if code == 33 else 3)])
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
                    recs.append(dict(font=font, h=h, col=col, x=m['tx'] + x, y=m['ty'] + y, glyph=gi))
                    x += adv
                g.align()
                p = g.pos
            return recs, rect


SS = 4
ARCADE = W + 'fonts_gfx/7_Arcade Classic.ttf'
TIMES = '/System/Library/Fonts/Supplemental/Times New Roman.ttf'
if not os.path.exists(TIMES):
    TIMES = os.environ.get('TIMES_TTF', TIMES)


def glyph_alpha(ttf, ch, size, pen_x, pen_y, box, sy=1.0):
    """alpha of a glyph whose pen is at (pen_x, pen_y) (world units), on the canvas of `box` at Z, scaled sy in y"""
    font = ImageFont.truetype(ttf, int(round(size * Z)))
    im = Image.new('L', (box.Wz, int(round(box.Hz / sy)) + 1), 0)
    ImageDraw.Draw(im).text(((pen_x - box.ox) * Z, (pen_y - box.oy) * Z / sy), ch, font=font, fill=255, anchor='ls')
    if sy != 1.0:
        im = im.resize((im.width, int(round(im.height * sy))), Image.LANCZOS).crop((0, 0, box.Wz, box.Hz))
    a = np.zeros((box.Hz, box.Wz), dtype=np.float32)
    arr = np.asarray(im, dtype=np.float32) / 255.0
    a[:arr.shape[0], :arr.shape[1]] = arr[:box.Hz, :box.Wz]
    return a


F7 = font_info(7)

# ---------------------------------------------------------------- score digits (sf: sprite 30 holds the field 29,
# placed at y scale 1.98; the code scales sf by min(max * 20, 100) %): one picture per digit, pivot on its pen
# position on the baseline, with the field's y scale baked in
ef = inst(30).display[1]
t29 = TX[ef['char']]
assert t29['font'] == 7 and t29['align'] == 'center' and t29['variable'].endswith('.score')
fm = ef['matrix']
SY = fm['d']
assert fm['a'] == 1.0 and fm['b'] == 0 and fm['c'] == 0
size = t29['height']
CH = '0123456789'
gx1 = max(F7['adv'][c] for c in CH) * size
gb = Box(-2, -F7['ascent'] * size * SY - 2, gx1 + 2, F7['descent'] * size * SY + 2, pad=0)
imgs = []
for ch in CH:
    a = glyph_alpha(ARCADE, ch, size, 0, 0, gb, sy=SY)
    imgs.append(white(np.clip(gb.reduce(a), 0, 1)))
save_anim('digit', imgs, gb.reg())
bx0, bx1, by0, by1 = t29['bounds']
meta['digits'] = dict(adv=[round(F7['adv'][c] * size, 4) for c in CH],
                      # the field in sf's coordinates: text area (2 px gutters), first baseline (y scaled by SY)
                      x0=round(fm['tx'] + bx0 + 2, 4), x1=round(fm['tx'] + bx1 - 2, 4),
                      base=round(fm['ty'] + (by0 + 2 + F7['ascent'] * size) * SY, 4),
                      sfx=esf['matrix']['tx'], sfy=esf['matrix']['ty'])

# ---------------------------------------------------------------- mcScore (11): score (10) rises from the bottom right
# corner and goes down again (22 frames, removed on the last one). The archive's frame scripts held it 30 frames on
# frame 11 (compt = 30; if (compt-- > 0) gotoAndPlay(_currentframe - 1)), but in the released kubik.swf the
# obfuscator turned them into `"5t 9)" = 30` and `"5t 9)" = NaN` (P-code): it never holds, as here
sc = G.sprites[11]
ys = []
cur = None
ms = inst(11)
for f in range(1, sc.nframes + 1):
    ms.goto_and_stop(f)
    e = ms.display.get(1)
    ys.append(None if e is None else e['matrix']['ty'])
    if e is not None:
        assert e['matrix']['tx'] == 0
assert ys[-1] is None
meta['scoreY'] = ys[:-1]
# score (10): the bar (shape 6) and a field (8 "BICOLOR !", 9 "MONOCOLOR !": Times New Roman, see above)
s10 = inst(10)
bar = depth_cmds(s10, [1])
sbx = Box(*union(bounds(bar), (-161, -24, 0, -3)), pad=1.0)
imgs = []
for f, tid in ((1, 8), (2, 9)):
    s10.goto_and_stop(f)
    e = s10.display[2]
    assert e['char'] == tid
    t = TX[tid]
    assert t['align'] == 'center' and t['color'] == '#ffffff' and not t['useOutlines']
    can = sbx.draw(bar)
    font = ImageFont.truetype(TIMES, int(round(t['height'] * Z)))
    tw = font.getlength(t['text']) / Z
    asc = font.getmetrics()[0] / Z
    bx0, bx1, by0, by1 = t['bounds']
    x = e['matrix']['tx'] + bx0 + 2 + (bx1 - bx0 - 4 - tw) / 2
    base = e['matrix']['ty'] + by0 + 2 + asc
    im = Image.new('L', (sbx.Wz, sbx.Hz), 0)
    ImageDraw.Draw(im).text(((x - sbx.ox) * Z, (base - sbx.oy) * Z), t['text'], font=font, fill=255, anchor='ls')
    a = np.asarray(im, dtype=np.float32)[..., None] / 255.0
    can = can * (1 - a) + np.concatenate([a, a, a, a], axis=-1)
    imgs.append(sbx.image(can))
save_anim('scorePanel', imgs, sbx.reg())

# ---------------------------------------------------------------- butEndGame (19): smc, the button (16: up 12, over
# 13, down 14, hit 15) at (150, 40), and the text (18: "Terminer la partie") whose alpha pulses (21 frames, looping)
be = inst(19)
esmc = be.display[1]
etx = be.display[4]
assert esmc['name'] == 'smc' and esmc['char'] == 16 and etx['char'] == 18
bm = esmc['matrix']
bbx = Box(bm['tx'] - 150, bm['ty'] - 36, bm['tx'] + 150, bm['ty'] + 36, pad=0.5)
imgs = []
for shp in (12, 13, 14):
    imgs.append(bbx.image(bbx.draw([('shape', shp, bm, R.NOCX)])))
save_anim('endButton', imgs, bbx.reg())
hx0, hx1, hy0, hy1 = G.shapes[15]
meta['endHit'] = [bm['tx'] + hx0, bm['tx'] + hx1, bm['ty'] + hy0, bm['ty'] + hy1]
tm = etx['matrix']
recs, trect = static_text(17)
t18 = inst(18).display[1]['matrix']
ox, oy = tm['tx'] + t18['tx'], tm['ty'] + t18['ty']
tbx = Box(ox + trect[0], oy + trect[2], ox + trect[1], oy + trect[3], pad=1.0)
can = tbx.canvas()
for r in recs:
    assert r['font'] == 7
    ch = chr(F7['codes'][r['glyph']])
    if ch == ' ':
        continue
    a = glyph_alpha(ARCADE, ch, r['h'], ox + r['x'], oy + r['y'], tbx)
    rgb = np.array(r['col'][:3], dtype=np.float32) / 255.0
    lay = np.concatenate([a[..., None] * rgb, a[..., None]], axis=-1)
    can = can * (1 - a[..., None]) + lay
save_anim('endText', [tbx.image(can)], tbx.reg())
al = []
for f in range(1, G.sprites[19].nframes + 1):
    be.goto_and_stop(f)
    al.append(alpha8(be.display[4]['cx']['mult'][3]))
meta['endTextAlpha'] = al

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:16]:
    print('  %-24s %8d px' % (k, v))
