"""Builds the Razor graphics for KadoKadeo from the original SWF (gfx.swf: the library of the released game.swf, same
shapes and timelines, readable names).

Clips (timeline tables played by razor.Clip, see clipexport.py):
  - mcBall: the 4 fruits (frame colour + 1), each with its smc (the eyes blinking when the code plays it); the fruit
    is a 42 x 42 bitmap (smoothed fill) kept at its native resolution, the eyelids are vector shapes;
  - partSlice: the 3 pieces of each fruit (frames (colour + 1) * 3 - i), bitmaps too, over nested mcSplash clips that
    play on their own (a random rotation on their first frame, a removeMovieClip that Flash ignores on a timeline
    clip: they loop every 72 frames);
  - mcSplash: the blood splash the code attaches (white: Col.setColor(mc, 0xFF0000) is a red tint at run time).
Pictures drawn by the game itself:
  - mcBg: the background, a 300 x 299 bitmap with a non-smoothed fill (Flash 8 draws it with the nearest pixel):
    doubled pixel by pixel;
  - mcIcon: its smc (3 icons, 18 x 18 bitmaps, non-smoothed) doubled pixel by pixel, with the glow the code gives the
    icon (Filt.glow(mc, 2, 2, 0x7D421C)) baked;
  - mcRazor: the blade (its smc, turned by the code: a smoothed bitmap at its native resolution) and the hub (a
    non-smoothed bitmap, doubled);
  - mcShade: the disc (sprite 26 under a solid colour per frame: a white silhouette tinted at run time) and the spark
    (sprite 36 at depth 3: its colour transform, scale and glow baked per frame, drawn with blendMode "add");
  - mcCommentAnim: the five texts of fxComment in Impact (white silhouettes: the red copy and the knockout glow of
    sprite 4 are drawn at run time), and the glyphs of the score field (+ and digits) through the matrix of the field.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: razor_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/razor holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, glob, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'razor', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)       # vector shapes
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)      # the smoothed bitmaps (fruits, pieces, blade) at their native resolution
for X in (G, G1):
    X.flash_replace = True
K = C.K


def bitmap_shapes():
    """ids of the shapes filled with a bitmap (FFDec SVG export: a pattern fill)"""
    return sorted(int(os.path.basename(f)[:-4]) for f in glob.glob(W + 'svg_gfx/*.svg') if 'pattern' in open(f).read())


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM = {
    (55, 1): [['x', 'rndRot']],     # mcSplash: _rotation = Math.random() * 360
    (55, 19): [['x', 'rmSelf']],    # mcSplash: removeMovieClip("") (ignored by Flash on the splashes of partSlice's timeline)
}

E = C.Exporter(G, SRC, '', CUSTOM)
E.bitmaps = (G1, bitmap_shapes())
# the fruit and its eyelids: the bitmap stays a CUT layer at its native resolution
E.strategy_for = {91: 'cut', 97: 'cut', 102: 'cut', 107: 'cut'}

E.export(108, 'mcBall', code=('smc',))
# (cut: the pieces are bitmaps, drawn from their native pixels; flattened they would come from the zoom 4 export)
E.export(80, 'partSlice', strategy='cut')
E.export(55, 'mcSplash')

ROOTS = ['mcBall', 'partSlice', 'mcSplash']
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [Ly['a'] for Ly in E.clips[nm]['layers'] if Ly['k'] == 2]
used = {Ly['a'] for nm in keep for Ly in E.clips[nm]['layers'] if Ly['k'] != 2}
for nm in [nm for nm in E.clips if nm not in keep]:
    for Ly in E.clips.pop(nm)['layers']:
        if Ly['k'] != 2 and Ly['a'] not in used:
            for a in (Ly['a'], Ly['a'] + 'W'):
                if a in E.area:
                    shutil.rmtree(os.path.join(SRC, a))
                    E.area.pop(a)
                    E.pivots.pop(a)
    print('  unused clip %s removed' % nm)

clips, pivots, area = E.clips, E.pivots, E.area
meta = {}


def entries(sid, frame=1):
    st = R.Instance(G, sid, ctrl={'__noactions__': True, sid: frame})
    return sorted(st.display.items())


def to_f(im):
    """PIL RGBA -> premultiplied float RGBA"""
    a = np.asarray(im.convert('RGBA'), dtype=np.float32) / 255.0
    return np.concatenate([a[..., :3] * a[..., 3:4], a[..., 3:4]], -1)


def save(name, arrays, reg):
    """premultiplied float RGBA arrays -> anim (pivot reg in px)"""
    imgs = [Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA') for a in arrays]
    E.write_anim(name, imgs, reg)


def over(top, bottom):
    """premultiplied top over bottom"""
    return top + bottom * (1 - top[..., 3:4])


def solid(rgb, a):
    return np.concatenate([np.array(rgb, dtype=np.float32)[None, None, :] / 255.0 * a[..., None], a[..., None]], -1)


def bitmap_of(shape):
    """(bitmap id, x, y of its top left corner) of a shape filled 1:1 with a bitmap (FFDec SVG export)"""
    s = open(W + 'svg_gfx/%d.svg' % shape).read()
    pt = re.search(r'patternTransform="matrix\(([^)]*)\)"', s).group(1)
    a, b, c, d, tx, ty = [float(v) for v in pt.split(',')]
    assert (a, b, c, d) == (1, 0, 0, 1) and tx == int(tx) and ty == int(ty), (shape, pt)
    return tx, ty


def nearest2(bid):
    """a bitmap drawn by a non-smoothed fill (nearest pixel), zoomed x2 like the zoomed Flash player"""
    im = Image.open(W + 'img_gfx/%d.png' % bid).convert('RGBA')
    return im.resize((im.width * K, im.height * K), Image.NEAREST)


def shape_entry(sid, depth):
    e = dict(entries(sid))[depth]
    return e


# ---------------------------------------------------------------- mcBg: shape 110, bitmap 109 (non-smoothed)
e = shape_entry(111, 1)
m = e['matrix']
assert e['char'] == 110 and (m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']) == (1, 0, 0, 1, 0, 0), e
assert bitmap_of(110) == (0, 0)
E.write_anim('bg', [nearest2(109)], (0, 0))

# ---------------------------------------------------------------- mcIcon: smc (sprite 20: shapes 15, 17, 19 on its 3
# frames, bitmaps 14, 16, 18 non-smoothed) with the glow of Game.initInter: Filt.glow(mc, 2, 2, 0x7D421C) = GlowFilter
# blur 2 x 2, strength 2, alpha 1, quality 1, drawn under the icon (stage pixels: the icons are never scaled)
GLOW_ICON = dict(blurX=2.0, blurY=2.0, strength=2.0, color=(0x7D, 0x42, 0x1C, 255), passes=1)
PAD = 6
ims = []
for f, (shp, bid) in enumerate(((15, 14), (17, 16), (19, 18)), 1):
    e = dict(entries(20, f))[1]
    assert e['char'] == shp, (f, e)
    x0, y0 = bitmap_of(shp)
    assert (x0, y0) == (-9, -9)
    big = nearest2(bid)
    cv = Image.new('RGBA', (big.width + 2 * PAD * K, big.height + 2 * PAD * K), (0, 0, 0, 0))
    cv.alpha_composite(big, (PAD * K, PAD * K))
    img = to_f(cv)
    g = np.clip(R.box_blur(img[..., 3], GLOW_ICON['blurX'] * K, GLOW_ICON['blurY'] * K, 1) * GLOW_ICON['strength'], 0, 1)
    ims.append(over(img, solid(GLOW_ICON['color'][:3], g)))
assert [e['name'] for d, e in entries(21)] == ['smc']
save('icon', ims, ((PAD - x0) * K, (PAD - y0) * K))

# ---------------------------------------------------------------- mcRazor: smc (sprite 83: shape 82, bitmap 81
# smoothed: native pixels, turned by the code) and the hub (shape 85, bitmap 84 non-smoothed: doubled)
er = dict(entries(86))
assert er[1]['name'] == 'smc' and er[1]['inst'].sid == 83 and er[3]['char'] == 85
assert [e['char'] for d, e in entries(83)] == [82]
for d in (1, 3):
    m = er[d]['matrix']
    assert (m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']) == (1, 0, 0, 1, 0, 0), m
bx, by = bitmap_of(82)
E.write_anim('razorBlade', [Image.open(W + 'img_gfx/81.png').convert('RGBA')], (-bx, -by))
hx, hy = bitmap_of(85)
E.write_anim('razorHub', [nearest2(84)], (-hx * K, -hy * K))

# ---------------------------------------------------------------- mcShade (sprite 37): d=1 sprite 26 under a solid colour
# (multiply 0 + offset) and an alpha on frames 1-44; d=3 sprite 36 (playing from its frame 1 with the parent) under a
# colour transform, a scale and a glow, blendMode "add", on frames 1-19; frame 45: removeMovieClip
ed = dict(entries(37))
assert ed[1]['inst'].sid == 26 and ed[3]['inst'].sid == 36 and ed[3]['blend'] == 'add'
disc_col, disc_alpha = [], []
NSH = G.sprites[37].nframes
for f in range(1, NSH):
    e = dict(entries(37, f))[1]
    m = e['matrix']
    assert (m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']) == (1, 0, 0, 1, 0, 0), m
    cx = e['cx']
    assert cx['mult'][:3] == [0.0, 0.0, 0.0] and cx['add'][3] == 0, cx
    disc_col.append((int(cx['add'][0]) << 16) | (int(cx['add'][1]) << 8) | int(cx['add'][2]))
    disc_alpha.append(round(cx['mult'][3], 5))
imgs, reg = E.render([E.group_cmds([(1, dict(ed[1], cx=R.NOCX))], C.WHITE)], K)
E.write_anim('shadeDisc', imgs, reg)
spark = []
for f in range(1, NSH):
    # (sprite 36 is placed on frame 1 and plays with its parent: on frame f)
    d = dict(sorted(R.Instance(G, 37, ctrl={'__noactions__': True, 37: f, 36: f}).display.items()))
    if 3 not in d:
        break
    assert d[3]['inst'].frame == f, (f, d[3]['inst'].frame)
    spark.append(E.group_cmds([(3, dict(d[3], blend=None))], R.NOCX))
imgs, reg = E.render(spark, K, margin=12)
E.write_anim('shadeSpark', imgs, reg)
meta['shade'] = dict(n=NSH, discCol=disc_col, discAlpha=disc_alpha, spark=len(spark))
print('shade', len(disc_col), 'disc frames,', len(spark), 'spark frames')


# ---------------------------------------------------------------- texts
def font_layouts(path):
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
        out[fid] = dict(codes=codes, ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


TX = swftext.all_edittexts(W + 'gfx.swf')
FONTS = font_layouts(W + 'gfx.swf')
IMPACT = W + 'fonts_gfx/1_impact.ttf'
SS = 4


def glyphs_alpha(ttf, size, placed, box, res, lin=(1, 0, 0, 1)):
    """alpha of glyphs [(char, pen x, baseline y)] (Flash layout: glyph by glyph at the font's advances) drawn in the
    coordinates of the field, through the linear map lin = (a, b, c, d) (x' = a x + c y, y' = b x + d y), on the world
    box (x0, y0, w, h) of the target at K * res px per unit"""
    x0, y0, w, h = box
    sc = K * res
    a, b, c, d = lin
    # the glyphs upright at SS x the target resolution, then mapped through lin
    font = ImageFont.truetype(ttf, int(round(size * sc * SS)))
    Wb, Hb = int(round(w * sc * SS)), int(round(h * sc * SS))
    det = a * d - b * c
    ia, ib, ic, id_ = d / det, -b / det, -c / det, a / det
    # upright canvas: the field coordinates of the box corners
    corners = [(x0, y0), (x0 + w, y0), (x0, y0 + h), (x0 + w, y0 + h)]
    fx = [ia * X + ic * Y for X, Y in corners]
    fy = [ib * X + id_ * Y for X, Y in corners]
    ux0, uy0 = min(fx) - 2, min(fy) - 2
    Wu, Hu = int(math.ceil((max(fx) + 2 - ux0) * sc * SS)), int(math.ceil((max(fy) + 2 - uy0) * sc * SS))
    up = Image.new('L', (Wu, Hu), 0)
    dr = ImageDraw.Draw(up)
    for ch, px, py in placed:
        dr.text(((px - ux0) * sc * SS, (py - uy0) * sc * SS), ch, font=font, fill=255, anchor='ls')
    # target pixel (i, j) -> world (x0 + i / s, y0 + j / s) -> field (inverse lin) -> upright pixel
    s = sc * SS
    co = (ia, ic, (ia * x0 + ic * y0 - ux0) * s, ib, id_, (ib * x0 + id_ * y0 - uy0) * s)
    out = up.transform((Wb, Hb), Image.AFFINE, co, resample=Image.BICUBIC)
    return np.asarray(out.resize((int(round(w * sc)), int(round(h * sc))), Image.BOX), dtype=np.float32) / 255.0


# mcCommentAnim (sprite 7): its smc (sprite 6) tweened on frames 1-21 (frame 22: removed, removeMovieClip); in sprite 6,
# smc (sprite 4, scaled by the code to fit the text) and _field (the score: _parent._score); in sprite 4, sprite 3 twice
# (smc: a red copy at 50 %, and a copy with an inner glow and a knockout outer glow); in sprite 3, `field` (variable
# _parent._parent._parent._txt, Impact 30, centred). fxComment reads field.textWidth: (Cs.mcw - 50) / textWidth is the
# scale of sprite 4
TEXTS = ["COMBO!", "SUPER COMBO!", "MONSTRUEUX!", "ARCHI-GORE!", "ORGIE DANS LE SANG!"]
t2 = TX[2]
assert t2['font'] == 1 and t2['align'] == 'center' and not t2['html'] and t2['variable'] == '_parent._parent._parent._txt', t2
lay = FONTS[1]
e3 = dict(entries(3))[1]
assert e3['char'] == 2 and e3['name'] == 'field'
m3 = e3['matrix']
assert m3['b'] == 0 and m3['c'] == 0 and m3['a'] == m3['d'], m3
e4 = dict(entries(4))
assert e4[1]['inst'].sid == 3 and e4[3]['inst'].sid == 3 and e4[1]['name'] == 'smc'
m41, m43 = e4[1]['matrix'], e4[3]['matrix']
assert m41 == m43 and (m41['a'], m41['b'], m41['c'], m41['d'], m41['ty']) == (1, 0, 0, 1, 0), (m41, m43)
cx41 = e4[1]['cx']
assert cx41['mult'][:3] == [0.0, 0.0, 0.0] and cx41['add'] == [255, 0, 0, 0], cx41
assert not e4[1].get('filters')
f43 = e4[3]['filters']
assert [f['type'] for f in f43] == ['glow', 'glow'] and f43[0]['inner'] and f43[1]['knockout'] and not f43[1]['inner'], f43
fx0, fx1, fy0, fy1 = t2['bounds']
size = t2['height']
widths = []
TEXT_RES = []
for i, s in enumerate(TEXTS):
    tw = sum(lay['adv'][c] for c in s) * size
    assert tw < fx1 - fx0 - 4, s       # one line
    widths.append(tw)
    ratio = (300 - 50) / tw
    # the text laid out in the field, in sprite 4's coordinates (sprite 3 at m41, the field at m3)
    pen = fx0 + 2 + (fx1 - fx0 - 4 - tw) / 2
    base = fy0 + 2 + lay['ascent'] * size
    placed = []
    for ch in s:
        placed.append((ch, m41['tx'] + m3['tx'] + pen * m3['a'], m41['ty'] + m3['ty'] + base * m3['a']))
        pen += lay['adv'][ch] * size
    # the box of the text in sprite 4, with room for the knockout glow (4 stage pixels, sprite 4 is shown at `ratio`)
    pad = 2 + 4 / ratio
    bx0 = m41['tx'] + m3['tx'] + (fx0 + 2 + (fx1 - fx0 - 4 - tw) / 2) * m3['a'] - pad
    bx1 = bx0 + tw * m3['a'] + 2 * pad
    by0 = m41['ty'] + m3['ty'] + fy0 * m3['a'] - pad
    by1 = m41['ty'] + m3['ty'] + fy1 * m3['a'] + pad
    # textures at 2 px per stage pixel once the text is at its size (the hold: sprite 6 at 1, sprite 4 at `ratio`)
    res = round(ratio, 4)
    TEXT_RES.append(res)
    box = (bx0, by0, bx1 - bx0, by1 - by0)
    a = glyphs_alpha(IMPACT, size * m3['a'], [(c, x, y) for c, x, y in placed], box, res)
    save('comment%d' % i, [solid((255, 255, 255), a)], (-box[0] * K * res, -box[1] * K * res))
# the frames of sprite 6 in mcCommentAnim
smc = []
for f in range(1, G.sprites[7].nframes + 1):
    d = dict(entries(7, f))
    if 1 not in d:
        smc.append(None)
        continue
    m = d[1]['matrix']
    assert m['b'] == 0 and m['c'] == 0, m
    smc.append([round(m['tx'], 4), round(m['ty'], 4), round(m['a'], 6), round(m['d'], 6)])
assert smc[-1] is None and all(x is not None for x in smc[:-1])
e6 = dict(entries(6))
assert e6[1]['inst'].sid == 4 and e6[1]['name'] == 'smc' and e6[5]['char'] == 5 and e6[5]['name'] == '_field'
m61 = e6[1]['matrix']
assert m61['b'] == 0 and m61['c'] == 0 and m61['tx'] == 0 and m61['ty'] == 0, m61
glow_k = f43[1]
# the score field (_field: edittext 5, Impact 30, centred, its colour) through its matrix, its glow (white, 2, 4)
t5 = TX[5]
assert t5['font'] == 1 and t5['align'] == 'center' and t5['variable'] == '_parent._score', t5
m5 = e6[5]['matrix']
f5 = e6[5]['filters']
assert [f['type'] for f in f5] == ['glow'] and not f5[0]['inner'] and not f5[0]['knockout'], f5
GLYPHS = '+0123456789'
gx0, gx1, gy0, gy1 = t5['bounds']
gsize = t5['height']
lin = (m5['a'], m5['b'], m5['c'], m5['d'])
rgb5 = tuple(int(t5['color'][i:i + 2], 16) for i in (1, 3, 5))
gw = max(lay['adv'][c] for c in GLYPHS) * gsize
# one picture per glyph, its pivot the pen position on the baseline (field coordinates 0, 0) mapped by lin
corners = [(-2, -lay['ascent'] * gsize - 2), (gw + 2, -lay['ascent'] * gsize - 2), (-2, lay['descent'] * gsize + 2),
           (gw + 2, lay['descent'] * gsize + 2)]
cxs = [lin[0] * x + lin[2] * y for x, y in corners]
cys = [lin[1] * x + lin[3] * y for x, y in corners]
gbox = (math.floor(min(cxs)), math.floor(min(cys)), math.ceil(max(cxs)) - math.floor(min(cxs)),
        math.ceil(max(cys)) - math.floor(min(cys)))
ims = [solid(rgb5, glyphs_alpha(IMPACT, gsize, [(ch, 0, 0)], gbox, 1.0, lin)) for ch in GLYPHS]
save('scoreGlyphs', ims, (-gbox[0] * K, -gbox[1] * K))
meta['comment'] = dict(texts=TEXTS, widths=widths, res=TEXT_RES, smc=smc[:-1], smcScale=[m61['a'], m61['d']],
                       red=[(int(cx41['add'][0]) << 16) | (int(cx41['add'][1]) << 8) | int(cx41['add'][2]), cx41['mult'][3]],
                       knock=[glow_k['blurX'], glow_k['blurY'], glow_k['strength'],
                              (glow_k['color'][0] << 16) | (glow_k['color'][1] << 8) | glow_k['color'][2], glow_k['passes']],
                       field=[m5['a'], m5['b'], m5['c'], m5['d'], m5['tx'], m5['ty']],
                       fieldX=gx0 + 2, fieldW=gx1 - gx0 - 4, fieldBase=gy0 + 2 + lay['ascent'] * gsize,
                       adv=[round(lay['adv'][c] * gsize, 4) for c in GLYPHS],
                       glow=[f5[0]['blurX'], f5[0]['blurY'], f5[0]['strength'],
                             (f5[0]['color'][0] << 16) | (f5[0]['color'][1] << 8) | f5[0]['color'][2], f5[0]['passes']])
print('comment', json.dumps(meta['comment'])[:400])

# ---------------------------------------------------------------- the clips of the pictures above (same tables as
# clipexport's: k 0 one picture per frame, k 1 a picture placed by m0 / m, k 2 a nested clip; coordinates in pixels of
# the clip, K x r per Flash pixel; a picture at res 0.5 is drawn at scale 2)
ID = [0.0, 0.0, 1.0, 1.0, 0.0]
clips['mcBg'] = dict(n=1, r=1.0, layers=[dict(k=0, a='bg', t=[1])])
# mcIcon: smc (sprite 20, 3 frames: gotoAndStop(colour + 1) by the code), the glow of mcIcon baked in its pictures
assert G.sprites[20].nframes == 3 and not G.sprites[20].actions
clips['iconSmc'] = dict(n=3, r=1.0, layers=[dict(k=1, a='icon', t=[1, 2, 3], m0=ID)])
clips['mcIcon'] = dict(n=1, r=1.0, layers=[dict(k=2, a='iconSmc', nm='smc', p=[1], m0=ID)])
# mcRazor: smc (the blade, res 0.5) and the hub
clips['mcRazor'] = dict(n=1, r=1.0, layers=[dict(k=1, a='razorBlade', nm='smc', t=[1], m0=[0.0, 0.0, 2.0, 2.0, 0.0]),
                                             dict(k=1, a='razorHub', t=[1], m0=ID)])
# mcShade: the disc (white, `tns` its solid colour, `al` its alpha) and the spark (blendMode "add": `bl`)
assert G.sprites[37].actions.get(NSH) and NSH == 45
nd, ns = len(disc_col), len(spark)
clips['mcShade'] = dict(n=NSH, r=1.0, layers=[
    dict(k=1, a='shadeDisc', t=[1] * nd + [0] * (NSH - nd), m0=ID, tns=disc_col + [0xFFFFFF] * (NSH - nd),
         al=disc_alpha + [0.0] * (NSH - nd)),
    dict(k=1, a='shadeSpark', t=list(range(1, ns + 1)) + [0] * (NSH - ns), m0=ID, bl='add')],
    acts={str(NSH): [['x', 'rmSelf']]})
# mcCommentAnim: smc (sprite 6) tweened on frames 1-21, removed on 22; its pictures (sprite 4's texts, _field's
# glyphs) are given by the game (razor.Comment). Frame scripts: 6 fxBam(), 11 the hold
# (if (_compt-- > 0) gotoAndPlay(_currentframe - 1)), 22 removeMovieClip("")
assert set(G.sprites[7].actions) == {6, 11, 22}, G.sprites[7].actions
n7 = G.sprites[7].nframes
clips['commentSmc'] = dict(n=1, r=1.0, layers=[])
clips['mcCommentAnim'] = dict(n=n7, r=1.0, layers=[dict(k=2, a='commentSmc', nm='smc', p=[1] * (n7 - 1) + [0],
                              m=[[m[0] * K, m[1] * K, m[2], m[3], 0.0] for m in smc[:-1]] + [ID])],
                              acts={'6': [['x', 'fxBam']], '11': [['x', 'hold']], '22': [['x', 'rmSelf']]})

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:25]:
    print('  %-24s %8d px' % (k, v))
