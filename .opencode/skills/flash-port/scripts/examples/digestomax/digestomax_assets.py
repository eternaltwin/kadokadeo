"""Builds the Digestomax graphics for KadoKadeo from the original SWF (gfx.swf: the library of the released game.swf,
same shapes and timelines, readable names).

Clips (timeline tables played by digestomax.Clip, see clipexport.py):
  - mcBall: the fruits (frames 1-6, 11-14: colour + 1) and Pioupiou (frame 21: its smc is the hero's animation, sprite
    146, whose labels the code plays); in that animation the code drives smc (the fruit in the beak, sprite 134, or the
    fruit swallowed upwards, sprite 143) and the frame scripts read fields the code sets on it: the cheeks (sprite 124:
    smc shown and scaled by `$big`), sprite 143 (its smc on frame `_fruit`, mirrored by `_sens`);
  - mcBallS / mcJaugeS: the same fruits and the stomach disc at the size of the stomach row (36 %);
  - piouExplode, partFruit (its smc on a random frame), partLight, partScore (its text field is drawn by the game,
    Digits.hx), mcWarning, mcBg.
Pictures drawn by the game itself:
  - the ground: initMap draws mcTile (frame 2 on the first row, frame 1 with its smc on a random frame below) into a
    300 x 200 BitmapData (white) : the tiles (anim "tile", their overflow included), drawn in the same order;
  - the timer (mcTimer): the frame (shape 19) and the band of its smc (sprite 24 sliding under the 100 x 8 rectangle
    mask that the code scales, its smc), the colour matrix of the smc's filters baked in the band, its glow drawn at
    run time with the colour through that matrix;
  - mcLevel: "x" + Cs.COMBO_LIMIT in Lithos Pro with the filters of the field (inner + outer glow), one picture per
    text (anim "levelText": x2 ... x40);
  - the digits of partScore's text field (Impact).
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: digestomax_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/digestomax holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'digestomax', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
K = C.K


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


FRUITS = rng((1, 6), (11, 14))          # mcBall frames of the fruits (colour + 1)

# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM = {
    (73, 34): [['x', 'rmSelf']],        # piouExplode: removeMovieClip("")
    (124, 1): [['x', 'big']],           # smc._visible = _parent.$big > 0; smc._xscale = smc._yscale = 50 + _parent.$big * 10
    (143, 1): [['x', 'fruit']],         # smc.gotoAndStop(_parent._fruit); smc._xscale = _parent._sens * 100
    (98, 9): [],                        # partScore: compt = 20 / the loop of frame 11: never reached (stop() on frame 6)
    (98, 11): [],
}


class Exporter(C.Exporter):
    # the cheeks (sprite 124) stay nested clips everywhere: their script runs at each placement (the unnamed ones of
    # "windUp" too)
    def alive(self, sid, ctrl):
        return sid == 124 or super().alive(sid, ctrl)


E = Exporter(G, SRC, '', CUSTOM)
# the masks of the fruit in the beak (mcMask, clipDepth) stay MASK layers of that nested clip
E.flat_masks = True
E.clip_res = [0.5, 1.0, 1.5, 2.0]
E.code_for = {
    146: ('smc',),                      # the hero's animation: skin.smc.smc (the fruit)
    143: ('smc',),                      # the fruit swallowed upwards (its script)
    124: ('smc',),                      # a cheek (its script)
}
E.frames_for = {134: FRUITS}            # the fruit in the beak: gotoAndStop(colour + 1)

E.export(148, 'mcBall', code=('smc',), frames=FRUITS + [21])
# the stomach row (displayStomach: _xscale 36): only the 4 plain fruits can be swallowed
E.export(148, 'mcBallS', frames=rng((1, 4)), res=0.375, strategy='flat')
E.export(150, 'mcJaugeS', res=0.375)
E.export(73, 'piouExplode', strategy='flat')
E.export(94, 'partFruit', code=('smc',))
E.export(76, 'partLight')
E.export(98, 'partScore', code=('smc',), frames=rng((1, 6)))
E.export(28, 'mcWarning')
E.export(152, 'mcBg', strategy='flat')

ROOTS = ['mcBall', 'mcBallS', 'mcJaugeS', 'piouExplode', 'partFruit', 'partLight', 'partScore', 'mcWarning', 'mcBg']
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [Ly['a'] for Ly in E.clips[nm]['layers'] if Ly['k'] == 2]
for nm in [nm for nm in E.clips if nm not in keep]:
    E.clips.pop(nm)
    print('  unused clip %s removed' % nm)

clips, pivots, area = E.clips, E.pivots, E.area
meta = {}

# masks (k 3): Flash uses only their coverage, PIXI's sprite mask multiplies by the red of the picture (mcMask is
# green): their pictures are made white
mask_anims = {Ly['a'] for c in clips.values() for Ly in c['layers'] if Ly['k'] == 3}
assert not mask_anims & {Ly['a'] for c in clips.values() for Ly in c['layers'] if Ly['k'] != 3}, mask_anims
for an in sorted(mask_anims):
    d = os.path.join(SRC, an)
    for fn in os.listdir(d):
        im = Image.open(os.path.join(d, fn)).convert('RGBA')
        a = im.split()[3]
        im = Image.new('RGBA', im.size, (255, 255, 255, 0))
        im.putalpha(a)
        im.save(os.path.join(d, fn), optimize=True)
print('white masks', sorted(mask_anims))


def inst(sid, frame=1):
    return R.Instance(G, sid, ctrl={'__noactions__': True, sid: frame})


def entries(sid, frame=1, depths=None):
    st = inst(sid, frame)
    return [(d, e) for d, e in sorted(st.display.items()) if depths is None or d in depths]


def raster(cmds, x0, y0, w, h, res=1.0, box=False):
    """draw commands on a canvas of the world box (x0, y0, w, h) at K * res px per unit: premultiplied float RGBA
    (box: reduced by area averaging, the coverage of each pixel like Flash's rasterizer, no ringing at the edges)"""
    sc = K * res
    rd = R.Renderer(G, sc)
    Wz, Hz = int(round(w * G.Z)), int(round(h * G.Z))
    cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
    rd.draw(cmds, cv, (x0, y0))
    im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    im = im.resize((int(round(w * sc)), int(round(h * sc))), Image.BOX if box else Image.LANCZOS)
    return np.asarray(im, dtype=np.float32) / 255.0


def save(name, arrays, reg):
    """premultiplied float RGBA arrays -> anim (pivot reg in px)"""
    imgs = [Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA') for a in arrays]
    E.write_anim(name, imgs, reg)


# ---------------------------------------------------------------- ground (Game.initMap)
# mcTile at (x * 32, y * 32) drawn into a white 300 x 200 BitmapData: frame 2 on the first row, frame 1 (its smc,
# sprite 11, on a random frame) below. One picture per tile (frame 1: the first row, 2..10: smc frames 1..9) on a
# 36 x 36 box from (-2, -2): the shapes go past the 32 px of a tile, drawn in the order of the loops. The bitmap has
# 1 px per Flash pixel (shown zoomed, unsmoothed): the tiles at res 0.5
TB = 2
TR = 0.5
tiles = [raster(E.group_cmds(entries(14, 2), R.NOCX), -TB, -TB, 32 + 2 * TB, 32 + 2 * TB, TR, box=True)]
for f in range(1, G.sprites[11].nframes + 1):
    st = R.Instance(G, 14, ctrl={'__noactions__': True, 14: 1, 11: f})
    tiles.append(raster(E.group_cmds(sorted(st.display.items()), R.NOCX), -TB, -TB, 32 + 2 * TB, 32 + 2 * TB, TR, box=True))
save('tile', tiles, (TB * K * TR, TB * K * TR))
meta['tileFrames'] = G.sprites[11].nframes

# ---------------------------------------------------------------- timer (mcTimer)
ents26 = dict(entries(26))
assert ents26[1]['char'] == 19 and ents26[2]['char'] == 25, ents26
m25 = ents26[2]['matrix']
assert m25['b'] == 0 and m25['c'] == 0 and m25['tx'] == 0 and m25['ty'] == 0, m25
fl = ents26[2]['filters']
assert [f['type'] for f in fl] == ['glow', 'colormatrix'], fl
glow, cm = fl[0], fl[1]['matrix']
assert not glow['inner'] and not glow['knockout'] and glow['passes'] == 1
assert all(abs(cm[i]) < 1e-9 for i in (3, 4, 8, 9, 13, 14)) and cm[15:] == (0.0, 0.0, 0.0, 1.0, 0.0), cm
M = np.array([cm[0:3], cm[5:8], cm[10:13]], dtype=np.float64)
# the frame (shape 19), registration at mcTimer's origin
b19 = G.shapes[19]
save('timerFrame', [raster(E.group_cmds([(1, ents26[1])], R.NOCX), b19[0] - 1, b19[2] - 1, b19[1] - b19[0] + 2,
                           b19[3] - b19[2] + 2)], ((1 - b19[0]) * K, (1 - b19[2]) * K))
# sprite 25: smc (sprite 21: shape 20, the mask, clipDepth 5) over the band (sprite 24 at d = 3, sliding)
e25 = dict(entries(25))
assert e25[1]['name'] == 'smc' and e25[1]['clip'] == 5 and e25[3]['char'] == 24
assert [e['char'] for e in R.Instance(G, 21).display.values()] == [20]
b20 = G.shapes[20]
assert b20 == [0.0, 100.0, 0.0, 8.0] or tuple(b20) == (0.0, 100.0, 0.0, 8.0), b20
band_tx = []
for f in range(1, G.sprites[25].nframes + 1):
    m = dict(entries(25, f))[3]['matrix']
    assert m['a'] == 1 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0 and m['ty'] == 0, m
    band_tx.append(m['tx'])
b23 = G.shapes[[e['char'] for e in R.Instance(G, 24).display.values()][0]]
band = raster(E.group_cmds([(3, dict(e25[3], matrix=R.IDENT))], R.NOCX), b23[0], b23[2], b23[1] - b23[0], b23[3] - b23[2])
# the colour matrix of the smc's filters, on the colours (not premultiplied; no offsets, alpha kept)
a = band[..., 3:4]
rgb = np.where(a > 0, band[..., :3] / np.maximum(a, 1e-9), 0)
rgb = np.clip(np.einsum('ij,hwj->hwi', M, rgb), 0, 1)
save('timerBand', [np.concatenate([rgb * a, a], -1).astype(np.float32)], (-b23[0] * K, -b23[2] * K))
gc = np.clip(M @ (np.array(glow['color'][:3], dtype=np.float64) / 255.0), 0, 1)
meta['timer'] = dict(bandTx=band_tx, bandX=b23[0], bandW=b23[1] - b23[0], maskW=b20[1], maskH=b20[3],
                     yscale=m25['d'], glow=[glow['blurX'], glow['blurY'], glow['strength'],
                                            (int(round(gc[0] * 255)) << 16) | (int(round(gc[1] * 255)) << 8) | int(round(gc[2] * 255))])
print('timer', meta['timer'])


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
SS = 4


def text_alpha(ttf, lay, size, s, x, base, box, res):
    """alpha of text s laid out like Flash (pen from x, glyph by glyph at the font's advances, on the baseline `base`)
    on the world box (x0, y0, w, h) at K * res px per unit"""
    x0, y0, w, h = box
    sc = K * res
    font = ImageFont.truetype(ttf, int(round(size * sc * SS)))
    big = Image.new('L', (int(round(w * sc * SS)), int(round(h * sc * SS))), 0)
    d = ImageDraw.Draw(big)
    pen = x
    for ch in s:
        d.text(((pen - x0) * sc * SS, (base - y0) * sc * SS), ch, font=font, fill=255, anchor='ls')
        pen += lay['adv'][ch] * size
    return np.asarray(big.resize((int(round(w * sc)), int(round(h * sc))), Image.LANCZOS), dtype=np.float32) / 255.0


def glow_alpha(a, f, res=1.0):
    """Flash GlowFilter (quality = passes box blurs of blurX x blurY stage pixels, times the strength)"""
    return np.clip(R.box_blur(a, f['blurX'] * K * res, f['blurY'] * K * res, f.get('passes', 1)) * f['strength'], 0, 1)


def over(top, bottom):
    """premultiplied top over bottom"""
    return top + bottom * (1 - top[..., 3:4])


def solid(rgb, a):
    return np.concatenate([np.array(rgb, dtype=np.float32)[None, None, :] / 255.0 * a[..., None], a[..., None]], -1)


# mcLevel.field: "x" + Cs.COMBO_LIMIT (Game.levelUp), right aligned, with the filters of its placement: inner glow
# then outer glow, each on the result of the previous one
t = TX[30]
assert t['font'] == 29 and t['align'] == 'right' and not t['html'], t
fe = dict(entries(31))[1]
assert fe['char'] == 30 and fe['name'] == 'field'
fm = fe['matrix']
assert fm['a'] == 1 and fm['d'] == 1 and fm['b'] == 0 and fm['c'] == 0, fm
lay = FONTS[29]
rgb = tuple(int(t['color'][i:i + 2], 16) for i in (1, 3, 5))
fx0, fx1, fy0, fy1 = t['bounds']
PAD = 8
box = (fm['tx'] + fx0 - PAD, fm['ty'] + fy0 - PAD, fx1 - fx0 + 2 * PAD, fy1 - fy0 + 2 * PAD)
right = fm['tx'] + fx1 - 2
base = fm['ty'] + fy0 + 2 + lay['ascent'] * t['height']
ff = fe['filters']
assert [f['type'] for f in ff] == ['glow', 'glow'] and ff[0]['inner'] and not ff[1]['inner'], ff
LEVELS = list(range(2, 41))
ims = []
for n in LEVELS:
    s = 'x%d' % n
    width = sum(lay['adv'][c] for c in s) * t['height']
    a = text_alpha(W + 'fonts_gfx/29_Lithos Pro Regular.ttf', lay, t['height'], s, right - width, base, box, 1.0)
    img = solid(rgb, a)
    # inner glow: the blurred outside (1 - alpha), inside the text, over it
    gi = np.clip(R.box_blur(1 - a, ff[0]['blurX'] * K, ff[0]['blurY'] * K, ff[0]['passes']) * ff[0]['strength'], 0, 1) * a
    img = over(solid(ff[0]['color'][:3], gi * ff[0]['color'][3] / 255.0), img)
    # outer glow, under it
    go = glow_alpha(img[..., 3], ff[1]) * ff[1]['color'][3] / 255.0
    img = over(img, solid(ff[1]['color'][:3], go))
    ims.append(img)
save('levelText', ims, (-box[0] * K, -box[1] * K))
meta['levels'] = LEVELS

# partScore.smc (sprite 97): its text field (variable _parent._score, Impact 20, centred, black), placed at 84 %; the
# digits as images whose pivot is the pen position on the baseline (res DIG_RES), laid out in smc by Digits.hx
t = TX[96]
assert t['font'] == 95 and t['align'] == 'center' and not t['html'] and t['variable'] == '_parent._score', t
fe = dict(entries(97))[1]
assert fe['char'] == 96 and fe['name'] == 'smc' and not fe.get('filters')
fm = fe['matrix']
assert fm['b'] == 0 and fm['c'] == 0 and fm['a'] == fm['d'], fm
lay = FONTS[95]
DIG_RES = 2.0
size = t['height'] * fm['a']
GLYPHS = '0123456789'
gw = max(lay['adv'][c] for c in GLYPHS) * size
box = (-2, -lay['ascent'] * size - 2, gw + 4, (lay['ascent'] + lay['descent']) * size + 4)
ims = [solid((255, 255, 255), text_alpha(W + 'fonts_gfx/95_Impact.ttf', lay, size, ch, 0, 0, box, DIG_RES)) for ch in GLYPHS]
sc = K * DIG_RES
imgs = [Image.fromarray(np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA') for a in ims]
E.write_anim('digits', imgs, (-box[0] * sc, -box[1] * sc))
fx0, fx1, fy0, fy1 = t['bounds']
meta['digits'] = dict(adv=[round(lay['adv'][c] * size, 4) for c in GLYPHS], x=fm['tx'] + (fx0 + 2) * fm['a'],
                      w=(fx1 - fx0 - 4) * fm['a'], base=fm['ty'] + (fy0 + 2 + lay['ascent'] * t['height']) * fm['a'],
                      res=DIG_RES)
# the resolution of partScore's smc picture (the digits are drawn in its pixels)
sl = [Ly for Ly in clips['partScore']['layers'] if Ly.get('nm') == 'smc']
assert len(sl) == 1 and sl[0]['k'] == 1, clips['partScore']
m98 = dict(entries(98))[1]['matrix']
meta['digits']['smcRes'] = round(m98['a'] / sl[0]['m'][0][2], 4)
print('digits', meta['digits'], 'smc layer', sl[0])

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:25]:
    print('  %-24s %8d px' % (k, v))
