"""Start screen of Chakre Bouddha (public/assets/img/gfx/artwork/chakrebouddha.jpg, 600 x 600) composed from the
pictures of chakrebouddha_assets.py (all from the SWF): a moment of a game as the code places it (there is no old
thumbnail of the game: the layout follows the screenshots of the archive, psd/screen0*.jpg). The dark Buddha, the lit
one under the mask (mcEnergy.mask at y = -230: some energy lost), the seven chakras at their places with their
GradientGlowFilters (bglow 2 and glow 8, quality 3, outer), the sacral chakra lit (mcActive: the select ring at 320 %
with its white glow, colour transform 0.3 + white), the lotus of a touch on the heart chakra (mcLotus frame 12 at
125 %, 0.3 + green, GradientGlow 32) with its points (Ginko, drop shadow 3) and the green neon (mcNeons frame 4).
Bitmaps drawn with the nearest pixel, like the game.
usage: chakrebouddha_artwork.py <out dir of chakrebouddha_assets.py> <out jpg>"""
import os, sys, math, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

OUT, DST = sys.argv[1], sys.argv[2]
meta = json.load(open(os.path.join(OUT, 'meta.json')))
pivots = json.load(open(os.path.join(OUT, 'pivots.json')))
K = 2
COLORS = [0xD71E1B, 0xF49924, 0xF8CE06, 0x79A63F, 0x2388BE, 0x728DFC, 0xB23FA5]
YS = [278, 250, 209, 168, 128, 60, 34]


def pic(name, i=1):
    im = Image.open(os.path.join(OUT, 'src', name, '%d.png' % i)).convert('RGBA')
    a = np.asarray(im, dtype=np.float32) / 255.0
    a[..., :3] *= a[..., 3:4]
    px, py = pivots[name]
    return a, (px * im.width, py * im.height)


def layer():
    return np.zeros((300 * K, 300 * K, 4), dtype=np.float32)


def over(dst, src):
    dst *= (1 - src[..., 3:4])
    dst += src


def place(dst, img, reg, x, y, s=1.0, res=K, rot=0.0, nearest=False):
    """a picture (res pixels per Flash pixel, registration reg) at (x, y) Flash pixels, scaled s, rotated rot degrees"""
    k = K * s / res
    c, sn = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    A = np.array([[c * k, -sn * k], [sn * k, c * k]])
    t = np.array([x * K, y * K]) - A @ np.array(reg)
    Ai = np.linalg.inv(A)
    off = -Ai @ t
    src = Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    out = src.transform((dst.shape[1], dst.shape[0]), Image.AFFINE, (Ai[0, 0], Ai[0, 1], off[0], Ai[1, 0], Ai[1, 1], off[1]),
                        resample=Image.NEAREST if nearest else Image.BICUBIC)
    over(dst, np.asarray(out, dtype=np.float32) / 255.0)


def glow(lay, blur, strength, color, passes):
    return R.apply_filter(lay, dict(type='glow', color=((color >> 16) & 255, (color >> 8) & 255, color & 255, 255),
                                    blurX=blur, blurY=blur, strength=strength, passes=passes), K)


def cx(lay, mult, add):
    """ColorTransform on the colours (premultiplied layer)"""
    a = lay[..., 3:4]
    rgb = np.where(a > 0, lay[..., :3] / np.maximum(a, 1e-6), 0)
    rgb = np.clip(rgb * np.array(mult, dtype=np.float32) + np.array(add, dtype=np.float32) / 255.0, 0, 1)
    return np.concatenate([rgb * a, a], axis=-1).astype(np.float32)


canvas = layer()
# mcBg: the dark Buddha, the lit one under the mask
bg, r = pic('bg')
place(canvas, bg, r, 0, 0, res=1, nearest=True)
lit, r = pic('lit')
litl = layer()
place(litl, lit, r, 0, 0, res=1, nearest=True)
MY = -230
mask = layer()
x0, x1, y0, y1 = meta['mask']['rect']
top = int(max(0, (MY + y0) * K))
bot = int(max(0, (MY + meta['mask']['y0'] + 1) * K))
mask[top:bot, int(x0 * K):int(x1 * K)] = 1
edge, r = pic('maskedge')
place(mask, edge, r, 0, MY)
litl *= mask[..., 3:4]
over(canvas, litl)

# the green neon (a high on the heart chakra)
neon, r = pic('neon', 4)
place(canvas, neon, r, 187, 21, res=1, nearest=True)

# the chakras with their glows (glow at a strength of its pulse)
for i, (y, col) in enumerate(zip(YS, COLORS)):
    lay = layer()
    ch, r = pic('chakra', i + 1)
    place(lay, ch, r, 150, y)
    lay = glow(lay, 2, 2, col, 3)
    lay = glow(lay, 8, 1.4 + 0.5 * math.sin(i * 1.7), col, 3)
    over(canvas, lay)

# the sacral chakra lit: mcActive at 320 %, alpha 60 %
lay = layer()
ring, r = pic('ring8', 1)
place(lay, ring, r, 150, 250, s=3.2, res=8)
lay = glow(lay, 8, 1, 0xFFFFFF, 1)
lay = cx(lay, [0.3, 0.3, 0.3], [255, 255, 255]) * 0.6
over(canvas, lay)

# the lotus of a touch on the heart chakra, with its points
LX, LY, LS = 150, 168, 1.25
lay = layer()
lotus, r = pic('lotus')
fr = meta['lotus'][11]
for m in fr:
    a, b, c_, d, tx, ty = m
    k = LS * K
    rot = -60
    cr, sr = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    # the clip (scale LS, rotation) then the matrix of the depth
    M = np.array([[cr, -sr], [sr, cr]]) @ np.array([[a, c_], [b, d]]) * k
    t = np.array([LX * K, LY * K]) + np.array([[cr, -sr], [sr, cr]]) @ np.array([tx, ty]) * k - M @ np.array(r)
    Mi = np.linalg.inv(M)
    off = -Mi @ t
    src = Image.fromarray(np.clip(lotus * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    out = src.transform((lay.shape[1], lay.shape[0]), Image.AFFINE, (Mi[0, 0], Mi[0, 1], off[0], Mi[1, 0], Mi[1, 1], off[1]),
                        resample=Image.NEAREST)
    over(lay, np.asarray(out, dtype=np.float32) / 255.0)
g = COLORS[3]
lay = glow(lay, 32, 1, g, 1)
lay = cx(lay, [0.3, 0.3, 0.3], [(g >> 16) & 255, (g >> 8) & 255, g & 255])
over(canvas, lay)
# its points (mcPoints at the lotus' scale, x + 0 for 4 digits)
lay = layer()
d = meta['digits']
s = '1269'
width = sum(d['adv'][d['chars'].index(ch)] for ch in s)
p = meta['points']
pen = p['x0'] + (p['x1'] - p['x0'] - width) / 2
for ch in s:
    k = d['chars'].index(ch)
    im, r = pic('digit', k + 1)
    place(lay, im, r, LX + pen * LS, LY + p['base'] * LS, s=LS, res=d['res'])
    pen += d['adv'][k]
lay = glow(lay, 3, 1, 0x000000, 3)
over(canvas, lay)

out = Image.fromarray(np.clip(canvas[..., :3] * 255 + 0.5, 0, 255).astype(np.uint8), 'RGB')
out.save(DST, quality=92)
print('artwork', DST, out.size)
