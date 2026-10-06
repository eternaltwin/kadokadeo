"""The start screen of Klinker Surprise (public/assets/img/gfx/artwork/klinkersurprise.jpg, 600 x 600), after the layout
of the old KadoKado thumbnail (artwork/old/klinkersurprise.gif, 176 x 167, a Kinder Surprise parody, removed with the
port: what this script needs from it is written below): a game scene washed out (drawn by the port: kart.mjs), the red
"melting" wave over its lower part (its outline and colours read from the old thumbnail, smoothed at 600 px) and the title
"Klinker / surprise" (K black, linker red, both outlined in white; surprise white outlined in red), each letter
stretched into its box of the old thumbnail (Arial Black: the title is not in the SWF).
usage: kart.py <scene png> <out jpg> [wash 0..1]
"""
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

SCENE, OUT = sys.argv[1], sys.argv[2]
WASH = float(sys.argv[3]) if len(sys.argv) > 3 else 0.45
W = 600
S = W / 176.0          # old thumbnail pixels -> artwork pixels
Z = 4                  # supersampling
FONT = '/System/Library/Fonts/Supplemental/Arial Black.ttf'
# colours of the old thumbnail: letters, K, wave
RED = np.array([238, 56, 29], dtype=np.float32) / 255
BLACK = np.array([32, 6, 6], dtype=np.float32) / 255
WAVE_RED = np.array([243, 74, 38], dtype=np.float32) / 255
WHITE = np.array([1, 1, 1], dtype=np.float32)

# top of the red wave in the old thumbnail, per column (rows of the first red pixel down to the bottom)
WAVE = [95, 95, 95, 95, 96, 96, 97, 98, 99, 99, 100, 103, 104, 107, 109, 110, 111, 112, 112, 112, 112, 112, 112, 111,
        111, 110, 108, 106, 103, 102, 100, 100, 99, 99, 98, 97, 97, 97, 97, 97, 97, 98, 98, 99, 100, 102, 103, 104, 106,
        108, 109, 111, 113, 115, 116, 117, 118, 118, 119, 119, 119, 119, 119, 119, 119, 118, 118, 117, 116, 115, 113,
        111, 110, 108, 106, 104, 97, 93, 90, 88, 87, 86, 85, 85, 84, 84, 84, 83, 83, 83, 83, 82, 82, 83, 83, 83, 83, 83,
        83, 84, 84, 85, 87, 89, 92, 98, 104, 107, 109, 110, 111, 112, 112, 112, 113, 113, 113, 113, 113, 113, 113, 112,
        112, 112, 111, 111, 111, 110, 109, 108, 107, 105, 104, 104, 103, 103, 103, 103, 103, 103, 103, 103, 104, 104,
        105, 105, 107, 110, 112, 113, 114, 115, 115, 115, 115, 115, 115, 114, 114, 113, 113, 111, 110, 108, 106, 104,
        103, 100, 99, 98, 98, 98, 98, 97, 97, 97]
# letter boxes of the title in the old thumbnail: (char, x0, x1, y0, y1, fill, outline), the boxes of "Klinker" are
# their fill (outlined around), the boxes of "surprise" include their outline
T = 2.0   # outline width, old pixels
LETTERS = [('K', 8, 21, 8, 28, BLACK), ('l', 36, 41, 8, 28, RED), ('i', 57, 62, 8, 28, RED), ('n', 78, 90, 12, 28, RED),
           ('k', 105, 116, 8, 28, RED), ('e', 131, 143, 12, 28, RED), ('r', 159, 167, 12, 28, RED)]
LETTERS2 = [('s', 6, 21, 39, 59), ('u', 28, 44, 39, 59), ('r', 52, 64, 39, 59), ('p', 71, 87, 39, 61),
            ('r', 95, 107, 39, 59), ('i', 114, 123, 35, 59), ('s', 130, 146, 39, 59), ('e', 152, 168, 39, 59)]

N = W * Z
img = np.asarray(Image.open(SCENE).convert('RGB').resize((N, N), Image.LANCZOS), dtype=np.float32) / 255
img = img * (1 - WASH) + WASH

# ---------------------------------------------------------------- the wave
xs = (np.arange(N) + 0.5) / (S * Z)
top = np.interp(xs, np.arange(len(WAVE)) + 0.5, np.array(WAVE, dtype=np.float32) + 0.5)
top = ndimage.gaussian_filter1d(top, 2.2 * S * Z / 2) * S * Z
yy = np.arange(N)[:, None] + 0.5
cover = np.clip(yy - top[None, :], 0, 1)[..., None]
# a little lighter at the top of the red, like the old one
grad = (1 - np.clip((yy - top[None, :]) / (N * 0.5), 0, 1))[..., None]
red = WAVE_RED[None, None, :] * (1 - 0.05 * grad) + 0.05 * grad * np.array([1.0, 0.55, 0.4], dtype=np.float32)
img = img * (1 - cover) + red * cover

# ---------------------------------------------------------------- the title
font = ImageFont.truetype(FONT, 600)


def glyph(ch, w, h):
    """the glyph's ink stretched to w x h (supersampled pixels): coverage 0..1"""
    m = Image.new('L', (900, 900), 0)
    ImageDraw.Draw(m).text((150, 50), ch, font=font, fill=255)
    m = m.crop(m.getbbox()).resize((max(1, int(round(w))), max(1, int(round(h)))), Image.LANCZOS)
    return np.asarray(m, dtype=np.float32) / 255


def put(mask, x, y, col):
    global img
    h, w = mask.shape
    sub = img[y:y + h, x:x + w]
    a = mask[..., None]
    img[y:y + h, x:x + w] = sub * (1 - a) + col[None, None, :] * a


def letter(ch, bx0, bx1, by0, by1, fill, stroke):
    t = T * S * Z
    x0, x1, y0, y1 = bx0 * S * Z, bx1 * S * Z, by0 * S * Z, by1 * S * Z
    g = glyph(ch, x1 - x0, y1 - y0)
    pad = int(t) + 4
    big = np.zeros((g.shape[0] + 2 * pad, g.shape[1] + 2 * pad), dtype=np.float32)
    big[pad:pad + g.shape[0], pad:pad + g.shape[1]] = g
    # outline: everything within t of the glyph, anti-aliased
    d = ndimage.distance_transform_edt(big < 0.5)
    out = np.clip(t + 0.5 - d, 0, 1)
    out = np.maximum(out, big)
    X, Y = int(round(x0)) - pad, int(round(y0)) - pad
    put(out, X, Y, stroke)
    put(big, X, Y, fill)


for ch, x0, x1, y0, y1, fill in LETTERS:
    letter(ch, x0, x1, y0, y1, fill, WHITE)
for ch, x0, x1, y0, y1 in LETTERS2:
    letter(ch, x0 + T, x1 - T, y0 + T, y1 - T, WHITE, RED)

res = Image.fromarray(np.clip(img * 255 + 0.5, 0, 255).astype(np.uint8), 'RGB').resize((W, W), Image.LANCZOS)
res.save(OUT, quality=92)
print(OUT, res.size)
