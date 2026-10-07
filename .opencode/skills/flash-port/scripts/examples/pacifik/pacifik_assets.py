"""Builds the Pacifik graphics for KadoKadeo from the released SWF (game.swf of KadoKado/Games/pacifik: the code plus
the gfx.swf library, instance names obfuscated: r1 = "-X", r2 = "0X", the score field s = "[").

Pacifik is line art: every vector shape is a stroke of 0.25 Flash pixel (a few of 0.5 or 1), which Flash draws at
least 1 pixel wide. The pictures are the original seen at 300 x 300 and drawn x2: the strokes of FFDec's SVG export
(paths in the coordinates of the shape) composed with the matrices of the timelines, each stroke max(width x scale,
1 Flash pixel) wide, rasterized by rsvg-convert at 2 pixels per Flash pixel. (Rendering FFDec's zoom 4 PNGs and
reducing them would draw these strokes half a Flash pixel wide: FFDec keeps them 1 pixel wide at its own zoom.)

Two families, packed in two sheets (see rebuild_assets.sh):
  - bitmaps (sheet "pacifikb", sampled without smoothing: non-smoothed bitmap fills, which Flash 8 draws with the
    nearest pixel), 1 texture pixel per Flash pixel: the background (mcBg), the dock (mcDock, also frame 3 of mcOnde)
    and the two waves of mcOnde;
  - vector pictures (sheet "pacifik"), 2 texture pixels per Flash pixel: mcCanon split around its smc (back: the box,
    front: the ring and the two struts; the code turns and slides smc), mcFire (smc), mcBall, mcBar, mcCar (its
    visible picture: r1, r2 and smc are invisible markers), mcBeware (chevrons + "CAUTION !!" in the embedded Tahoma)
    and the four scores of mcScore ("100" "200" "400" "800", white, in the device font Tahoma Bold: tinted by the code's
    textColor at run time).
The particles (mcBallPart, mcCanonPart, mcLaserPart, mcCarPart, mcSmoke) are polylines grown by the code up to ~9x:
their segments are written in meta.json and drawn at run time 1 Flash pixel wide (or wider: Flash scales a stroke once
it is over 1 pixel), like Flash.
Also in meta.json: the bounds of the shapes that the code measures (getBounds, _width, _height) and the positions of
the markers of mcCar per frame.
Writes <out>/src (images), <out>/pivots.json, <out>/meta.json, <out>/bitmaps.json.
usage: pacifik_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/pacifik holds game.swf + exports)
"""
import os, sys, json, shutil, math, struct, zlib, subprocess, re, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'pacifik', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)
TMP = tempfile.mkdtemp()

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'game.swf', W + 'shp4_game', Z=4)
G.flash_replace = True

pivots = {}
area = {}
meta = {}
BITMAPS = []

S = {n: G.names[n] for n in ('mcBg', 'mcDock', 'mcOnde', 'mcCanon', 'mcFire', 'mcBall', 'mcBar', 'mcCar', 'mcBeware',
                             'mcScore', 'mcBallPart', 'mcCanonPart', 'mcLaserPart', 'mcCarPart', 'mcSmoke', 'mcHitShip',
                             'mcReactor')}
print('symbols', S)


def save_anim(name, imgs, reg, bitmap=False):
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    w, h = imgs[0].size
    for i, im in enumerate(imgs):
        assert im.size == (w, h), (name, im.size, (w, h))
        im.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(reg[0] / w, 6), round(reg[1] / h, 6)]
    a = 0
    for im in imgs:
        bb = im.split()[3].getbbox()
        if bb:
            a += (bb[2] - bb[0]) * (bb[3] - bb[1])
    area[name] = a
    if bitmap:
        BITMAPS.append(name)


# ---------------------------------------------------------------- timelines
def display(sid, frame):
    """the display list of a sprite at a frame: [(depth, entry)], entry = char, matrix, name, inst"""
    inst = R.Instance(G, sid, ctrl={sid: frame, '__noactions__': True})
    return sorted(inst.display.items()), inst


def leaves(sid, frame, M=R.IDENT, skip=()):
    """the shapes drawn by a sprite at a frame, with their matrices (nested sprites at their frame 1, like the code
    leaves them): [(shape id, matrix)]"""
    out = []

    def walk(inst, M):
        for d, e in sorted(inst.display.items()):
            m = R.mat_mul(M, e['matrix'])
            if e['inst'] is not None:
                if e['name'] in skip:
                    continue
                walk(e['inst'], m)
            elif e['char'] in G.shapes:
                out.append((e['char'], m))

    _, inst = display(sid, frame)
    walk(inst, M)
    return out


def rect_through(r, m):
    """a rectangle (x0, x1, y0, y1) through a matrix: its bounding box (what Flash's getBounds does per shape)"""
    pts = [(x, y) for x in (r[0], r[1]) for y in (r[2], r[3])]
    xs = [m['a'] * x + m['c'] * y + m['tx'] for x, y in pts]
    ys = [m['b'] * x + m['d'] * y + m['ty'] for x, y in pts]
    return [min(xs), max(xs), min(ys), max(ys)]


def union(rs):
    return [min(r[0] for r in rs), max(r[1] for r in rs), min(r[2] for r in rs), max(r[3] for r in rs)]


def r4(v):
    return [round(x, 4) for x in v]


# ---------------------------------------------------------------- strokes (FFDec SVG export)
PATH_RE = re.compile(r'<path ([^>]*)/>')
ATTR_RE = re.compile(r'([\w:-]+)="([^"]*)"')


def shape_paths(cid):
    """the strokes of a shape: [dict(d, stroke, opacity, width, fill)] in the coordinates of the shape"""
    txt = open(W + 'svg_game/%d.svg' % cid).read()
    assert '<image' not in txt and 'Pattern' not in txt, cid
    out = []
    for m in PATH_RE.finditer(txt):
        a = dict(ATTR_RE.findall(m.group(1)))
        w = float(a.get('ffdec:original-stroke-width', a.get('stroke-width', '0')))
        out.append(dict(d=a['d'], stroke=a.get('stroke', 'none'), opacity=float(a.get('stroke-opacity', '1')),
                        width=w, fill=a.get('fill', 'none'), fill_opacity=float(a.get('fill-opacity', '1')),
                        cap=a.get('stroke-linecap', 'round'), join=a.get('stroke-linejoin', 'round')))
    return out


def svg_doc(items, x0, y0, w, h, k):
    """an SVG of strokes [(paths, matrix)] over the Flash rectangle x0, y0, w, h, at k pixels per Flash pixel"""
    out = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%r %r %r %r">'
           % (int(round(w * k)), int(round(h * k)), x0, y0, w, h)]
    for paths, m in items:
        s = math.sqrt(abs(m['a'] * m['d'] - m['b'] * m['c']))
        out.append('<g transform="matrix(%r %r %r %r %r %r)">' % (m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']))
        for p in paths:
            # Flash: the stroke scaled with the clip, at least 1 pixel (of the 300 x 300 stage)
            sw = max(p['width'] * s, 1.0) / s if p['stroke'] != 'none' else 0
            out.append('<path d="%s" fill="%s" fill-opacity="%r" stroke="%s" stroke-opacity="%r" stroke-width="%r" '
                       'stroke-linecap="%s" stroke-linejoin="%s"/>'
                       % (p['d'], p['fill'], p['fill_opacity'], p['stroke'], p['opacity'], sw, p['cap'], p['join']))
        out.append('</g>')
    out.append('</svg>')
    return '\n'.join(out)


def rasterize(svg):
    src = os.path.join(TMP, 'a.svg')
    dst = os.path.join(TMP, 'a.png')
    open(src, 'w').write(svg)
    subprocess.check_call(['rsvg-convert', '-o', dst, src])
    return Image.open(dst).convert('RGBA')


def vector_frames(frames, pad=1.5, k=K):
    """lists of (shape id, matrix), one per frame, drawn on one common canvas: (images, registration in px)"""
    bbs = []
    for fr in frames:
        for cid, m in fr:
            bbs.append(rect_through(G.shapes[cid], m))
    bb = union(bbs)
    step = 1.0 / k
    ox = math.floor((bb[0] - pad) / step) * step
    oy = math.floor((bb[2] - pad) / step) * step
    ex = math.ceil((bb[1] + pad) / step) * step
    ey = math.ceil((bb[3] + pad) / step) * step
    imgs = []
    for fr in frames:
        items = [(shape_paths(cid), m) for cid, m in fr]
        imgs.append(rasterize(svg_doc(items, ox, oy, ex - ox, ey - oy, k)))
    return imgs, (-ox * k, -oy * k)


def vector_anim(name, frames, **kw):
    imgs, reg = vector_frames(frames, **kw)
    save_anim(name, imgs, reg)


# ---------------------------------------------------------------- bitmaps (1 texture pixel per Flash pixel)
def shape_bitmap(cid):
    """a shape filled with a bitmap, from the zoom 1 export (its pixels are the bitmap's), with its top left corner"""
    x0, x1, y0, y1 = G.shapes[cid]
    im = Image.open(W + 'shp1_game/%d.png' % cid).convert('RGBA')
    assert (im.width, im.height) == (round(x1 - x0), round(y1 - y0)), (cid, im.size, G.shapes[cid])
    return im, (x0, y0)


def bitmap_anim(name, cid):
    im, o = shape_bitmap(cid)
    save_anim(name, [im], (-o[0], -o[1]), bitmap=True)


(_, bg), = [(d, e) for d, e in display(S['mcBg'], 1)[0] if e['inst'] is None]
bitmap_anim('bg', bg['char'])
# (mcBg also holds a mcDock placed at (859, -182): out of the stage, never seen)
(_, dock), = display(S['mcDock'], 1)[0]
bitmap_anim('dock', dock['char'])
ONDE = []
for f in range(1, G.sprites[S['mcOnde']].nframes + 1):
    (_, e), = display(S['mcOnde'], f)[0]
    ONDE.append(e['char'])
# (frame 3 is the dock's shape: the same picture)
assert ONDE[2] == dock['char']
bitmap_anim('onde1', ONDE[0])
bitmap_anim('onde2', ONDE[1])
meta['ondeHeights'] = [G.shapes[c][3] - G.shapes[c][2] for c in ONDE]
meta['dockHeight'] = G.shapes[dock['char']][3] - G.shapes[dock['char']][2]

# ---------------------------------------------------------------- mcCanon: back (d1), smc (mcFire), front (d4)
CANON_BACK, CANON_FRONT = [], []
for f in range(1, G.sprites[S['mcCanon']].nframes + 1):
    dl, _ = display(S['mcCanon'], f)
    shapes = [(d, e) for d, e in dl if e['inst'] is None]
    smc = [(d, e) for d, e in dl if e['name'] == 'smc']
    assert len(shapes) == 2 and len(smc) == 1 and shapes[0][0] < smc[0][0] < shapes[1][0], dl
    assert smc[0][1]['matrix'] == R.IDENT or all(abs(smc[0][1]['matrix'][k] - R.IDENT[k]) < 1e-9 for k in R.IDENT)
    CANON_BACK.append(shapes[0][1]['char'])
    CANON_FRONT.append(shapes[1][1]['char'])
vector_anim('canonb', [[(c, R.IDENT)] for c in CANON_BACK])
vector_anim('canonf', [[(c, R.IDENT)] for c in CANON_FRONT])
FIRE = []
for f in range(1, G.sprites[S['mcFire']].nframes + 1):
    (_, e), = display(S['mcFire'], f)[0]
    FIRE.append(e['char'])
vector_anim('fire', [[(c, R.IDENT)] for c in FIRE])
meta['canonBack'] = [r4(G.shapes[c]) for c in CANON_BACK]
meta['canonFront'] = [r4(G.shapes[c]) for c in CANON_FRONT]
meta['fire'] = [r4(G.shapes[c]) for c in FIRE]

# ---------------------------------------------------------------- mcBall, mcBar
BALL = []
for f in range(1, G.sprites[S['mcBall']].nframes + 1):
    (_, e), = display(S['mcBall'], f)[0]
    BALL.append(e['char'])
vector_anim('ball', [[(c, R.IDENT)] for c in BALL])
meta['ball'] = [r4(G.shapes[c]) for c in BALL]
BAR = []
for f in range(1, G.sprites[S['mcBar']].nframes + 1):
    (_, e), = display(S['mcBar'], f)[0]
    BAR.append(e['char'])
vector_anim('bar', [[(c, R.IDENT)] for c in BAR])

# ---------------------------------------------------------------- mcCar: picture + markers per frame
CAR_NAMES = {'smc': 'smc', '-X': 'r1', '0X': 'r2'}
car_frames, car_meta = [], []
hit = G.shapes[display(S['mcHitShip'], 1)[0][0][1]['char']]
reac = G.shapes[display(S['mcReactor'], 1)[0][0][1]['char']]
for f in range(1, G.sprites[S['mcCar']].nframes + 1):
    dl, _ = display(S['mcCar'], f)
    marks = {}
    for d, e in dl:
        if e['name'] in CAR_NAMES:
            m = e['matrix']
            assert abs(m['a'] - 1) < 1e-9 and abs(m['d'] - 1) < 1e-9 and m['b'] == 0 and m['c'] == 0, (f, e)
            marks[CAR_NAMES[e['name']]] = [round(m['tx'], 4), round(m['ty'], 4)]
    car_frames.append(leaves(S['mcCar'], f, skip=tuple(CAR_NAMES)))
    # the bounds of the clip (the invisible markers count: getBounds measures every shape)
    rs = [rect_through(G.shapes[c], m) for c, m in leaves(S['mcCar'], f)]
    car_meta.append(dict(bounds=r4(union(rs)), smc=marks['smc'], r1=marks.get('r1'), r2=marks.get('r2')))
vector_anim('car', car_frames)
meta['car'] = car_meta
meta['hitShip'] = r4(hit)
meta['reactor'] = r4(reac)
print('car', car_meta)

# ---------------------------------------------------------------- particles: segments
def segments(cid):
    """the segments of a polyline shape (M / L only): [x1, y1, x2, y2] and its stroke"""
    paths = shape_paths(cid)
    assert len(paths) == 1, cid
    p = paths[0]
    toks = re.findall(r'[MLZ]|-?[\d.]+', p['d'])
    assert 'Q' not in p['d'] and 'Z' not in toks, (cid, p['d'])
    segs = []
    cur = None
    i = 0
    cmd = None
    while i < len(toks):
        t = toks[i]
        if t in ('M', 'L'):
            cmd = t
            i += 1
            continue
        x, y = float(toks[i]), float(toks[i + 1])
        i += 2
        if cmd == 'L' and cur is not None:
            segs.append([cur[0], cur[1], x, y])
        cur = (x, y)
        if cmd == 'M':
            cmd = 'L'
    assert p['opacity'] == 1 and p['fill'] == 'none', (cid, p)
    return dict(segs=segs, color=int(p['stroke'][1:], 16), width=p['width'])


PARTS = {}
for name in ('mcBallPart', 'mcCanonPart', 'mcLaserPart', 'mcCarPart', 'mcSmoke'):
    fr = []
    for f in range(1, G.sprites[S[name]].nframes + 1):
        (_, e), = display(S[name], f)[0]
        m = e['matrix']
        assert all(abs(m[k] - R.IDENT[k]) < 1e-9 for k in R.IDENT), (name, m)
        fr.append(segments(e['char']))
    PARTS[name] = fr
meta['parts'] = PARTS
print('parts', {k: len(v) for k, v in PARTS.items()})

# ---------------------------------------------------------------- text
TX = swftext.all_edittexts(W + 'game.swf')
raw = open(W + 'game.swf', 'rb').read()
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


def text_place(sid, name=None):
    dl, _ = display(sid, 1)
    (d, e), = [(d, e) for d, e in dl if e['char'] in TX and (name is None or e['name'] == name)]
    return TX[e['char']], e['matrix']


def draw_glyphs(canvas, font_path, size, s, x, base, k, ox, oy, spacing, adv, color, SS=4):
    """draws a string glyph by glyph (Flash layout: advances + letter spacing) on an RGBA canvas"""
    font = ImageFont.truetype(font_path, int(round(size * k * SS)))
    big = Image.new('L', (canvas.width * SS, canvas.height * SS), 0)
    dr = ImageDraw.Draw(big)
    pen = x
    for ch in s:
        dr.text((((pen - ox) * k) * SS, ((base - oy) * k) * SS), ch, font=font, fill=255, anchor='ls')
        pen += adv(ch) + spacing
    a = big.resize(canvas.size, Image.LANCZOS)
    layer = Image.new('RGBA', canvas.size, color + (0,))
    layer.putalpha(a)
    return Image.alpha_composite(canvas, layer)


# mcBeware: the chevrons (d1) and "CAUTION !!" (html: Tahoma bold 8, letterSpacing 2, centred, #ccff33), embedded
# font: one picture (nothing in it moves)
bt, bm = text_place(S['mcBeware'])
assert bt['useOutlines'] and abs(bt['height'] - 8) < 1e-9
FB = font_layout(bt['font'])
TTF_B = W + 'fonts_game/%d_Tahoma.ttf' % bt['font']
B_TEXT = re.sub(r'<[^>]*>', '', bt['text'])
B_SPACING = float(re.search(r'letterSpacing="([\d.]+)"', bt['text']).group(1))
B_SIZE = 8.0
assert B_TEXT == 'CAUTION !!', B_TEXT
line_w = sum(FB['adv'][c] * B_SIZE + B_SPACING for c in B_TEXT)
bx0 = bm['tx'] + bt['bounds'][0] + 2
bx1 = bm['tx'] + bt['bounds'][1] - 2
b_left = bx0 + (bx1 - bx0 - line_w) / 2.0
b_base = bm['ty'] + bt['bounds'][2] + 2 + FB['ascent'] * B_SIZE
chev = leaves(S['mcBeware'], 1)
# the canvas widened to the text
cb = union([rect_through(G.shapes[c], m) for c, m in chev] +
           [[b_left - 2, b_left + line_w + 2, b_base - FB['ascent'] * B_SIZE - 2, b_base + FB['descent'] * B_SIZE + 2]])
ox, oy = math.floor(cb[0] - 1), math.floor(cb[2] - 1)
ex, ey = math.ceil(cb[1] + 1), math.ceil(cb[3] + 1)
canvas = rasterize(svg_doc([(shape_paths(c), m) for c, m in chev], ox, oy, ex - ox, ey - oy, K))
col = tuple(int(bt['color'][i:i + 2], 16) for i in (1, 3, 5))
canvas = draw_glyphs(canvas, TTF_B, B_SIZE, B_TEXT, b_left, b_base, K, ox, oy, B_SPACING,
                     lambda c: FB['adv'][c] * B_SIZE, col)
save_anim('beware', [canvas], (-ox * K, -oy * K))

# mcScore: field "[" (s) in the device font Tahoma Bold 10 (not embedded: drawn by the system of the player, Windows
# for most), centred; its text is the score of a ball. Drawn white, coloured by the code's textColor.
st, sm = text_place(S['mcScore'], '[')
assert not st['useOutlines'] and st['fontInfo']['bold'] and st['fontInfo']['name'] == 'Tahoma'
TTF_S = '/System/Library/Fonts/Supplemental/Tahoma Bold.ttf'
S_SIZE = st['height']
tt = ImageFont.truetype(TTF_S, 1000)
# (ascent of the device font: Tahoma's usWinAscent 2049 / 2048 em)
S_ASC = 2049 / 2048.0
sx0 = sm['tx'] + st['bounds'][0] + 2
sx1 = sm['tx'] + st['bounds'][1] - 2
s_base = sm['ty'] + st['bounds'][2] + 2 + S_ASC * S_SIZE
SCORES = ['100', '200', '400', '800']
s_imgs = []
for s in SCORES:
    wpx = tt.getlength(s) / 1000.0 * S_SIZE
    left = sx0 + (sx1 - sx0 - wpx) / 2.0
    ox, oy = math.floor(sx0 - 2), math.floor(s_base - S_ASC * S_SIZE - 2)
    ex, ey = math.ceil(sx1 + 2), math.ceil(s_base + 0.25 * S_SIZE + 2)
    c = Image.new('RGBA', (int((ex - ox) * K), int((ey - oy) * K)), (255, 255, 255, 0))
    c = draw_glyphs(c, TTF_S, S_SIZE, s, left, s_base, K, ox, oy, 0,
                    lambda ch: tt.getlength(ch) / 1000.0 * S_SIZE, (255, 255, 255))
    s_imgs.append(c)
save_anim('score', s_imgs, (-ox * K, -oy * K))
meta['scores'] = SCORES
print('score field', sx0, sx1, s_base)

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(BITMAPS, open(os.path.join(OUT, 'bitmaps.json'), 'w'))
shutil.rmtree(TMP)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k_, v in sorted(area.items(), key=lambda x: -x[1])[:14]:
    print('  %-24s %8d px' % (k_, v))
