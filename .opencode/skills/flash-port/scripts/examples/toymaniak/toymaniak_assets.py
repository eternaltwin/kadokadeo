"""Builds the Toy Maniak graphics for KadoKadeo from the original SWF.

The released toymania.swf holds gfx.swf with obfuscated export and instance names (same ids, same timelines, same
shapes: checked by comparing the dumps), so the pictures are rendered from gfx.swf, whose names are readable.

Toy Maniak has no character animation: every symbol is rendered at x2 ("simple renders" pipeline) and the code
(Game.hx, Gfx.hx, MC.hx) plays the few timelines from tables:
  - bg, box (its 3 slots: base, bar and the toy that falls in, both under the slot's mask);
  - toy: one picture per frame of its timeline (the 7 bitmap toys at their native resolution, 1 texture pixel per Flash
    pixel: Flash drew them smoothed, like the GPU; the 4 vector ones at x2), with the matrix of the frame and the bounds
    of the clip (Game.updateCursor centres the toy in hand on its getBounds, which counts the invisible button);
  - railFront: the belt (shape 44), the two treads (the 8 x 2 bitmaps repeated, native), the cruncher (shown through
    the rectangle of shape 51: a scissor rectangle at run time), the end (shape 56);
  - railBack: the machine and the panel (one picture), the lights green and red (10 frames each), the digits of the
    counter (font Digital, embedded).
The shapes that mix vector fills and bitmap fills (44, 53, 56, 59) are rendered by rsvg-convert from the FFDec SVG
(the bitmap smoothed, as Flash drew it; FFDec's PNG export draws bitmap fills unsmoothed).
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: toymaniak_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/toymaniak holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess, io, re, base64
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'toymaniak', '')
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


def render(cmds, pad=1.0):
    b = Box(*RD.bounds(cmds), pad=pad)
    return b.image(b.draw(cmds)), b.reg()


def mat_pt(m, x, y):
    return m['a'] * x + m['c'] * y + m['tx'], m['b'] * x + m['d'] * y + m['ty']


def flash_bounds(sid, frame=1, M=R.IDENT):
    """MovieClip.getBounds as Flash computes it: the bounds of every shape (its DefineShape rectangle) through the
    matrices, invisible children included (the alpha 0 button of the toy)"""
    xs, ys = [], []

    def walk(s, f, m):
        i = inst(s)
        i.goto_and_stop(f)
        for d in sorted(i.display):
            e = i.display[d]
            mm = R.mat_mul(m, e['matrix'])
            if e['char'] in G.sprites:
                walk(e['char'], 1, mm)
            elif e['char'] in G.shapes:
                x0, x1, y0, y1 = G.shapes[e['char']]
                for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
                    px, py = mat_pt(mm, x, y)
                    xs.append(px)
                    ys.append(py)
    walk(sid, frame, M)
    # (in twips, like Flash: 24.99997 is 25, the cursor of Game.updateCursor lands where the original's did)
    return [twips(min(xs)), twips(max(xs)), twips(min(ys)), twips(max(ys))]


def twips(v):
    return round(v * 20) / 20


# ---------------------------------------------------------------- shapes with bitmap fills
def svg_of(cid):
    return open(W + 'svg_gfx/%d.svg' % cid).read()


def rsvg_shape(cid):
    """the shape rendered by rsvg-convert at zoom Z on the grid of FFDec's PNG (bitmap fills smoothed)"""
    w, h = G.shape_image(cid).size
    svg = re.sub(r'height="[^"]*px" width="[^"]*px"', 'height="%gpx" width="%gpx"' % (h / Z, w / Z), svg_of(cid), count=1)
    r = subprocess.run(['rsvg-convert', '-z', str(Z)], input=svg.encode(), capture_output=True, check=True)
    im = Image.open(io.BytesIO(r.stdout)).convert('RGBA')
    assert im.size == (w, h), (cid, im.size, (w, h))
    return im


for cid in (44, 53, 56, 59):
    assert 'optimizeQuality' in svg_of(cid)
    G._shape_cache[cid] = rsvg_shape(cid)


def native_bitmap(cid):
    """a shape that is one bitmap fill (its whole rectangle, unscaled, at whole or half pixels: whole pixels of the
    screen at x2): the bitmap at its native resolution and its origin in the shape"""
    svg = svg_of(cid)
    assert svg.count('<path') == 1 and svg.count('<image') == 1, cid
    m = re.search(r'patternTransform="matrix\(([^)]*)\)"', svg)
    a, b, c, d, tx, ty = [float(v) for v in m.group(1).split(',')]
    assert (a, b, c, d) == (1, 0, 0, 1) and tx * 2 == int(tx * 2) and ty * 2 == int(ty * 2), (cid, m.group(1))
    data = re.search(r'xlink:href="data:image/[A-Za-z]+;base64,([^"]*)"', svg).group(1)
    im = Image.open(io.BytesIO(base64.b64decode(data))).convert('RGBA')
    x0, x1, y0, y1 = G.shapes[cid]
    assert (x0, y0) == (tx, ty) and (x1 - x0, y1 - y0) == im.size, (cid, G.shapes[cid], im.size)
    return im, (-tx, -ty)


# ---------------------------------------------------------------- bg (76), box (42)
c = depth_cmds(inst(76), [15])
im, reg = render(c, pad=0.5)
save_anim('bg', [im], reg)

bi = inst(42)
im, reg = render(depth_cmds(bi, [1]))
save_anim('box', [im], reg)
meta['slots'] = {bi.display[d]['name']: [bi.display[d]['matrix']['tx'], bi.display[d]['matrix']['ty'], d]
                 for d in (2, 14, 26)}

# ---------------------------------------------------------------- slot (41): base (shape 37), mask (shape 38, clipDepth
# 11 over the bar and the toy), bar (sprite 40) and toy moved by the timeline
si = inst(41)
assert si.display[2]['char'] == 37 and si.display[3]['char'] == 38 and si.display[3]['clip'] == 11
im, reg = render(depth_cmds(si, [2]))
save_anim('slot', [im], reg)
# the mask, white (a PIXI sprite mask uses the red channel)
mc = depth_cmds(si, [3])
b = Box(*RD.bounds(mc), pad=1.0)
a = b.draw(mc)[..., 3]
wm = np.zeros(a.shape + (4,), dtype=np.float32)
wm[..., :] = a[..., None]
save_anim('slotMask', [b.image(wm)], b.reg())
assert si.display[4]['char'] == 40
im, reg = render(depth_cmds(inst(40), [2]))
save_anim('slotBar', [im], reg)
sp = G.sprites[41]
bar, toy = [], []
for f in range(1, sp.nframes + 1):
    si.goto_and_stop(f)
    eb = si.display.get(4)
    et = si.display.get(7)
    assert eb is not None and eb['matrix']['tx'] == -0.1 and eb['matrix']['a'] == 1
    bar.append(eb['matrix']['ty'])
    if et is None:
        toy.append(None)
    else:
        assert et['char'] == 35 and et['name'] == 'toy' and et['matrix']['a'] == 1 and et['matrix']['tx'] == -0.45
        toy.append(et['matrix']['ty'])
meta['slot'] = dict(frames=sp.nframes, labels=sp.labels, barX=-0.1, bar=bar, toyX=-0.45, toy=toy,
                    actions={str(k): str(v) for k, v in sp.actions.items()})
# hit area of a slot (the clip has onPress): its shapes, the children through the mask; shape 37 and the mask 38 have
# the same outline, so it is shape 37: a run-length mask at 4 samples per Flash pixel (its alpha >= 0.5)
HS = 4
x0, x1, y0, y1 = G.shapes[37]
s37 = np.asarray(G.shape_image(37), dtype=np.float32)[..., 3] / 255.0
assert s37.shape == (int(round((y1 - y0) * Z)), int(round((x1 - x0) * Z))) and Z == HS
rows = []
for y in range(s37.shape[0]):
    r = s37[y] >= 0.5
    runs = []
    xx = 0
    while xx < len(r):
        if r[xx]:
            s = xx
            while xx < len(r) and r[xx]:
                xx += 1
            runs += [s, xx]
        else:
            xx += 1
    rows.append(runs)
meta['slotHit'] = dict(x0=x0, y0=y0, res=HS, rows=rows)

# ---------------------------------------------------------------- toy (35): frames 1-11 one picture each (depth 3),
# 12-16 the picture of 11, 17-23 none; the button "but" (depth 1, alpha 0) is never drawn
ti = inst(35)
eb = ti.display[1]
assert eb['name'] == 'but' and eb['char'] == 2 and inst(2).display[1]['char'] == 1
bx0, bx1, by0, by1 = G.shapes[1]
bm = eb['matrix']
p0 = mat_pt(bm, bx0, by0)
p1 = mat_pt(bm, bx1, by1)
meta['butRect'] = [twips(p0[0]), twips(p1[0]), twips(p0[1]), twips(p1[1])]
pics = {}
toyframes = []
for f in range(1, G.sprites[35].nframes + 1):
    ti.goto_and_stop(f)
    e = ti.display.get(3)
    if e is None:
        toyframes.append(None)
    else:
        m = e['matrix']
        assert m['b'] == 0 and m['c'] == 0
        sid = e['char']
        if sid not in pics:
            pics[sid] = len(pics)
            si2 = inst(sid)
            shp = [si2.display[d] for d in si2.display]
            if len(shp) == 1 and shp[0]['char'] in G.shapes and '<image' in svg_of(shp[0]['char']):
                assert shp[0]['matrix'] == R.IDENT
                im, reg = native_bitmap(shp[0]['char'])
                res = 1
            else:
                cm = []
                RD.collect(si2, R.IDENT, R.NOCX, set(), cm)
                im, reg = render(cm)
                res = K
            save_anim('toy%d' % pics[sid], [im], reg)
            meta.setdefault('toyRes', []).append(res)
        toyframes.append([pics[sid], m['tx'], m['ty'], m['a'], m['d']])
    if f in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 20):
        pass
meta['toyFrames'] = toyframes
meta['toyBounds'] = [flash_bounds(35, f) for f in range(1, G.sprites[35].nframes + 1)]

# ---------------------------------------------------------------- railFront (57), frame 1
fi = inst(57)
d = fi.display
assert d[2]['char'] == 44 and d[3]['name'] == 't0' and d[5]['name'] == 't1' and d[7]['char'] == 51 and d[7]['clip'] == 13
assert d[8]['name'] == 'cruncher' and d[8]['char'] == 54 and d[16]['char'] == 56
im, reg = render(depth_cmds(fi, [2]))
save_anim('front', [im], reg)
im, reg = render(depth_cmds(fi, [16]))
save_anim('frontEnd', [im], reg)
# treads (50: frame 1 sprite 47 = shape 46, frame 2 shape 49): 8 x 2 bitmaps repeated over 308 x 2, native
for name, cid in (('tread0', 46), ('tread1', 49)):
    svg = svg_of(cid)
    assert 'matrix(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)' in svg and G.shapes[cid] == [0.0, 308.0, 0.0, 2.0]
    im = Image.open(W + 'shp1_gfx/%d.png' % cid).convert('RGBA')
    assert im.size == (308, 2)
    save_anim(name, [im], (0, 0))
i50 = inst(50)
assert i50.display[1]['char'] == 47 and inst(47).display[1]['char'] == 46 and inst(47).display[1]['matrix'] == R.IDENT
i50.goto_and_stop(2)
assert i50.display[1]['char'] == 49 and i50.display[1]['matrix'] == R.IDENT
cm = depth_cmds(inst(54), [4])
im, reg = render(cm)
save_anim('cruncher', [im], reg)
mx0, mx1, my0, my1 = G.shapes[51]
assert d[7]['matrix'] == R.IDENT
meta['front'] = dict(t0=[d[3]['matrix']['tx'], d[3]['matrix']['ty']], t1=[d[5]['matrix']['tx'], d[5]['matrix']['ty']],
                     cruncher=[d[8]['matrix']['tx'], d[8]['matrix']['ty']], mask=[mx0, mx1, my0, my1])

# ---------------------------------------------------------------- railBack (74): the machine (59) and the panel (73:
# 61, 62 under the field and the lights) in one picture
ki = inst(74)
assert ki.display[2]['char'] == 59 and ki.display[3]['name'] == 'panel'
pm = ki.display[3]['matrix']
pi = inst(73)
pd = pi.display
assert pd[1]['char'] == 61 and pd[5]['char'] == 62 and pd[6]['name'] == 'field' and pd[7]['name'] == 'green' and pd[11]['name'] == 'red'
cm = depth_cmds(ki, [2]) + depth_cmds(pi, [1, 5], pm)
im, reg = render(cm)
save_anim('back', [im], reg)
lights = {}
for name, dd in (('green', 7), ('red', 11)):
    e = pd[dd]
    sid = e['char']
    li = inst(sid)
    cms = []
    for f in range(1, G.sprites[sid].nframes + 1):
        li.goto_and_stop(f)
        cm = []
        RD.collect(li, R.IDENT, R.NOCX, set(), cm)
        cms.append(cm)
    bb = [RD.bounds(c) for c in cms]
    b = Box(min(x[0] for x in bb), min(x[1] for x in bb), max(x[2] for x in bb), max(x[3] for x in bb))
    save_anim(name, [b.image(b.draw(c)) for c in cms], b.reg())
    lights[name] = dict(x=pm['tx'] + e['matrix']['tx'], y=pm['ty'] + e['matrix']['ty'],
                        actions={str(k): str(v) for k, v in G.sprites[sid].actions.items()})
meta['lights'] = lights
meta['panel'] = [pm['tx'], pm['ty']]

# ---------------------------------------------------------------- the counter (field 64: font Digital 15, left, white)
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


ef = pd[6]
t = TX[ef['char']]
assert t['font'] == 63 and t['align'] == 'left' and t['color'] == '#ffffff' and t['useOutlines']
assert t['leftMargin'] == 0 and t['indent'] == 0
F = font_info(63)
size = t['height']
TTF = W + 'fonts_gfx/63_Digital.ttf'
SS = 4
pxs = size * K * SS
font = ImageFont.truetype(TTF, int(round(pxs)))
assert abs(int(round(pxs)) - pxs) < 1e-6
pad = 3
dw = int(math.ceil(max(F['adv'][ch] for ch in '0123456789') * size * K)) + 2 * pad + 4
dh = int(math.ceil((F['ascent'] + F['descent']) * size * K)) + 2 * pad + 2
ox, oy = pad + 1, pad + int(math.ceil(F['ascent'] * size * K))
imgs = []
for ch in '0123456789':
    big = Image.new('L', (dw * SS, dh * SS), 0)
    ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
    al = big.resize((dw, dh), Image.LANCZOS)
    g = Image.new('RGBA', (dw, dh), (255, 255, 255, 0))
    g.putalpha(al)
    imgs.append(g)
save_anim('digit', imgs, (ox, oy))
fx, fy = pm['tx'] + ef['matrix']['tx'], pm['ty'] + ef['matrix']['ty']
bx0, bx1, by0, by1 = t['bounds']
# Flash lays out a text field with a 2 px gutter: the first baseline at the top + 2 + ascent
meta['digits'] = dict(adv=[round(F['adv'][ch] * size, 4) for ch in '0123456789'], x=fx + bx0 + 2,
                      base=fy + by0 + 2 + F['ascent'] * size)

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:16]:
    print('  %-24s %8d px' % (k, v))
