"""Builds the Chakre Bouddha graphics for KadoKadeo from the original SWF (gfx.swf, KadoKado/Games/chakras).

No timeline logic: every picture is a single render ("simple renders" pipeline), placed by the code like the original.
Two families, packed in two sheets (see rebuild_assets.sh):
  - bitmaps (sheet "chakrebouddhab", sampled without smoothing: their shapes use non-smoothed bitmap fills, fill style
    0x43, which Flash 8 draws with the nearest pixel): the dark and the lit Buddha (mcBg), the lotus bitmap (mcLotus
    places it 6 times per frame: its 39 frames are exported as matrices, not as pictures), the 7 neons (mcNeons), the 2
    rocks (mcRock); 1 texture pixel per Flash pixel, their native resolution;
  - vector pictures (sheet "chakrebouddha"), 2 texture pixels per Flash pixel unless said: the 8 frames of mcChakra
    (their GradientGlowFilters are drawn at run time: the strength changes every frame), the same at 0.4 pixel per
    Flash pixel (drawn into the plasma bitmap, Bmp.drawMc at pq = 0.4), the ring of mcActive (frame 1: select at 75 %
    without the GlowFilter of its timeline, drawn at run time in stage pixels; frame 2: badselect) at several
    resolutions (the code scales mcActive up to ~1100 %), the lower edge of mcMask (the mask of the lit Buddha: its
    rectangle is drawn at run time), the glyphs of the Ginko font (field "text" of mcPoints) at 4 pixels per Flash
    pixel and "0" "5" at 16 (BonusAnim grows the 5000 up to ~900 %), and the two static lines of mcBonus.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: chakrebouddha_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/chakrebouddha holds gfx.swf + exports, and
       shp32_gfx: FFDec -format shape:png -zoom 32 -selectid 50,52 -export shape shp32_gfx gfx.swf)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'chakrebouddha', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
# the rings, at up to 24 texture pixels per Flash pixel: shapes 50 and 52 exported at zoom 32
G32 = R.SWF(W + 'gfx.swf', W + 'shp32_gfx', Z=32)
G32.flash_replace = True

pivots = {}
area = {}
meta = {}
# animations of the bitmap sheet (the others go to the vector sheet)
BITMAPS = []

# symbols (gfx.swf ids)
S_LOTUS, S_NEONS, S_ROCK, S_POINTS, S_BONUS, S_SELECT, S_BADSELECT, S_CHAKRA, S_MASK, S_MM1 = \
    16, 31, 39, 41, 8, 53, 51, 71, 75, 74
SH_BG, SH_LIT, SH_LOTUS = 77, 79, 15
SH_NEONS = [18, 20, 22, 24, 26, 28, 30]
SH_ROCKS = [36, 38]
T_POINTS, T_BONUS1, T_BONUS2 = 40, 6, 7


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


def instance(g, sid, ctrl=None):
    return R.Instance(g, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def scale(s, tx=0.0, ty=0.0):
    return dict(a=s, b=0.0, c=0.0, d=s, tx=tx, ty=ty)


def cmds_of(sid, ctrl=None, M=R.IDENT, cx=R.NOCX, hide=(), g=G):
    out = []
    R.Renderer(g, K).collect(instance(g, sid, ctrl), M, cx, set(hide), out)
    return out


def render(items, pad=0.5, k=K, g=G):
    """command lists drawn on one common canvas (at the zoom of the shapes, reduced to k pixels per Flash pixel);
    returns (images, registration in px)"""
    rd = R.Renderer(g, K)
    Z = g.Z
    bb = None
    for cmds in items:
        b = rd.bounds(cmds)
        if b:
            bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    step = 1.0 / k
    ox = math.floor((bb[0] - pad) / step) * step
    oy = math.floor((bb[1] - pad) / step) * step
    ex = math.ceil((bb[2] + pad) / step) * step
    ey = math.ceil((bb[3] + pad) / step) * step
    Wz, Hz = int(round((ex - ox) * Z)), int(round((ey - oy) * Z))
    w, h = int(round((ex - ox) * k)), int(round((ey - oy) * k))
    imgs = []
    for cmds in items:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        imgs.append(im.resize((w, h), Image.LANCZOS).convert('RGBA'))
    return imgs, (-ox * k, -oy * k)


def shape_bitmap(cid):
    """a shape filled with a bitmap, from the zoom 1 export (its pixels are the bitmap's: 1 pixel per Flash pixel),
    with the position of its top left corner"""
    x0, x1, y0, y1 = G.shapes[cid]
    return Image.open(W + 'shp1_gfx/%d.png' % cid).convert('RGBA'), (x0, y0)


def bitmap_anim(name, cids):
    """bitmap shapes as the frames of one animation (a common canvas, the origins of the shapes kept)"""
    parts = [shape_bitmap(c) for c in cids]
    x0 = min(o[0] for _, o in parts)
    y0 = min(o[1] for _, o in parts)
    x1 = max(o[0] + im.width for im, o in parts)
    y1 = max(o[1] + im.height for im, o in parts)
    imgs = []
    for im, o in parts:
        assert o[0] == int(o[0]) and o[1] - y0 == int(o[1] - y0), (name, o)
        c = Image.new('RGBA', (int(x1 - x0), int(math.ceil(y1 - y0))), (0, 0, 0, 0))
        c.paste(im, (int(o[0] - x0), int(o[1] - y0)))
        imgs.append(c)
    save_anim(name, imgs, (-x0, -y0), bitmap=True)


# ---------------------------------------------------------------- bitmaps (1 texture pixel per Flash pixel)
bitmap_anim('bg', [SH_BG])
bitmap_anim('lit', [SH_LIT])
bitmap_anim('lotus', [SH_LOTUS])
bitmap_anim('neon', SH_NEONS)
bitmap_anim('rock', SH_ROCKS)


# mcLotus: 39 frames, 6 depths placing the lotus bitmap (shape 15) with a matrix each
def lotus_timeline():
    sp = G.sprites[S_LOTUS]
    cur = {}
    frames = []
    for ops in sp.frames:
        for op, p in ops:
            if op == 'place':
                d = p['depth']
                m = p.get('matrix')
                if not p.get('move'):
                    assert p['char'] == SH_LOTUS, p
                if m is not None:
                    cur[d] = m
            elif op == 'remove':
                cur.pop(p, None)
        frames.append([[round(cur[d][k], 5) for k in ('a', 'b', 'c', 'd', 'tx', 'ty')] for d in sorted(cur)])
    return frames


meta['lotus'] = lotus_timeline()
assert len(meta['lotus']) == 39 and all(len(f) == 6 for f in meta['lotus'])

# ---------------------------------------------------------------- mcChakra: the 8 frames (7 chakras, chakranoir)
imgs, reg = render([cmds_of(S_CHAKRA, {S_CHAKRA: f}) for f in range(1, 9)])
save_anim('chakra', imgs, reg)
# drawn into the plasma bitmap (0.4 bitmap pixel per Flash pixel)
imgs, reg = render([cmds_of(S_CHAKRA, {S_CHAKRA: f}) for f in range(1, 9)], k=0.4, pad=1.25)
save_anim('chakrap', imgs, reg)

# ---------------------------------------------------------------- mcActive: select (smc at 75 %) and badselect
RING_RES = [2, 4, 8, 16, 24]
for r in RING_RES:
    # frame 1: the GlowFilter of smc is drawn at run time; frame 2: badselect placed at (0, -1.2)
    imgs, reg = render([cmds_of(S_SELECT, M=scale(0.75), g=G32), cmds_of(S_BADSELECT, M=scale(1, 0, -1.2), g=G32)],
                       k=r, pad=0.5, g=G32)
    save_anim('ring%d' % r, imgs, reg)
meta['ringRes'] = RING_RES

# ---------------------------------------------------------------- mcMask (mask of the lit Buddha in mcBg)
# its rectangle (shape 72, 0..300 x 0..296) is drawn at run time; the picture is the mask from y = MASK_Y0 down: the
# bottom of the rectangle and mm1 (the edge with its dots), white
MASK_Y0 = 256.0
mk = cmds_of(S_MASK, cx=dict(mult=[0.0, 0.0, 0.0, 1.0], add=[255, 255, 255, 0]))
rd = R.Renderer(G, K)
bb = rd.bounds(mk)
ox, oy = math.floor(bb[0]), MASK_Y0
ex, ey = math.ceil(bb[2]), math.ceil(bb[3]) + 1
Z = G.Z
canvas = np.zeros((int((ey - oy) * Z), int((ex - ox) * Z), 4), dtype=np.float32)
rd.draw(mk, canvas, (ox, oy))
im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
im = im.resize((int((ex - ox) * K), int((ey - oy) * K)), Image.LANCZOS).convert('RGBA')
save_anim('maskedge', [im], (-ox * K, -oy * K))
meta['mask'] = dict(y0=MASK_Y0, rect=list(G.shapes[72]))
print('mask', bb, meta['mask'])

# ---------------------------------------------------------------- text: Ginko (embedded, DefineFont3)
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


tp = TX[T_POINTS]
FONT = font_layout(tp['font'])
TTF = W + 'fonts_gfx/5_Ginko.ttf'
SIZE = tp['height']
assert TX[T_BONUS1]['height'] == SIZE and TX[T_BONUS2]['height'] == SIZE


def glyph_images(chars, k, pad=2):
    """the glyphs of the font, white, k pixels per Flash pixel, all on one canvas: origin = (left, baseline)"""
    SS = 4
    font = ImageFont.truetype(TTF, int(round(SIZE * k * SS)))
    gw = int(math.ceil(max(FONT['adv'][c] for c in chars) * SIZE * k)) + 2 * pad + int(4 * k)
    gh = int(math.ceil((FONT['ascent'] + FONT['descent']) * SIZE * k)) + 2 * pad + int(2 * k)
    ox, oy = pad + int(math.ceil(k)), pad + int(math.ceil(FONT['ascent'] * SIZE * k))
    out = []
    for ch in chars:
        big = Image.new('L', (gw * SS, gh * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        a = big.resize((gw, gh), Image.LANCZOS)
        im = Image.new('RGBA', (gw, gh), (255, 255, 255, 0))
        im.putalpha(a)
        out.append(im)
    return out, (ox, oy)


def field(t, place):
    """Flash layout of a field placed at (tx, ty): text area x0..x1 (2 px gutter), first baseline"""
    b = t['bounds']
    return dict(x0=round(place[0] + b[0] + 2, 4), x1=round(place[0] + b[1] - 2, 4),
                base=round(place[1] + b[2] + 2 + FONT['ascent'] * SIZE, 4), align=t['align'])


DIGITS = '0123456789'
imgs, reg = glyph_images(DIGITS, 4)
save_anim('digit', imgs, reg)
# BonusAnim: the only text grown far (mcPoints of the 5000, vsc 1.14)
BIG = '05'
imgs, reg = glyph_images(BIG, 16)
save_anim('digitbig', imgs, reg)
meta['digits'] = dict(chars=DIGITS, big=BIG, res=4, bigRes=16,
                      adv=[round(FONT['adv'][c] * SIZE, 4) for c in DIGITS])
pl = [e for e in instance(G, S_POINTS).display.values() if e['name'] == 'text'][0]['matrix']
meta['points'] = field(tp, (pl['tx'], pl['ty']))
print('points field', meta['points'])


# mcBonus: two static lines, centred in their fields, drawn on one picture in the coordinates of mcBonus (4 pixels
# per Flash pixel)
def bonus_text(k=4):
    items = []
    for tid in (T_BONUS1, T_BONUS2):
        e = [e for e in instance(G, S_BONUS).display.values() if e['char'] == tid][0]['matrix']
        t = TX[tid]
        f = field(t, (e['tx'], e['ty']))
        s = t['text']
        width = sum(FONT['adv'][c] for c in s) * SIZE
        items.append((s, f, f['x0'] + (f['x1'] - f['x0'] - width) / 2.0))
    x0 = min(x for _, _, x in items) - 4
    x1 = max(x + sum(FONT['adv'][c] for c in s) * SIZE for s, _, x in items) + 4
    y0 = min(f['base'] for _, f, _ in items) - FONT['ascent'] * SIZE - 4
    y1 = max(f['base'] for _, f, _ in items) + FONT['descent'] * SIZE + 4
    canvas = Image.new('RGBA', (int(math.ceil((x1 - x0) * k)), int(math.ceil((y1 - y0) * k))), (255, 255, 255, 0))
    for s, f, x in items:
        glyphs, (gx, gy) = glyph_images(s, k, pad=2)
        pen = x
        for c, g in zip(s, glyphs):
            layer = Image.new('RGBA', canvas.size, (255, 255, 255, 0))
            layer.paste(g, (int(round((pen - x0) * k)) - gx, int(round((f['base'] - y0) * k)) - gy))
            canvas = Image.alpha_composite(canvas, layer)
            pen += FONT['adv'][c] * SIZE
    return canvas, (-x0 * k, -y0 * k)


im, reg = bonus_text()
save_anim('bonustext', [im], reg)

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(BITMAPS, open(os.path.join(OUT, 'bitmaps.json'), 'w'))
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k_, v in sorted(area.items(), key=lambda x: -x[1])[:14]:
    print('  %-24s %8d px' % (k_, v))
