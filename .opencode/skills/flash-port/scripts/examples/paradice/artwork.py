"""Start screen of Paradice (public/assets/img/gfx/artwork/paradice.jpg, 600x600): a scene of the game rendered from
the SWF (background, gems in the grid, penguins carrying balls, window frame) after the layout of the old thumbnail
(artwork/old/paradice.gif), with the title band of that thumbnail (the title exists nowhere else) enlarged on it.
usage: artwork.py <repository root>"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import numpy as np
from PIL import Image, ImageFilter
from paradice_swf import G, Gq, Gd, R

REPO = sys.argv[1]
K = 2


def draw(canvas, X, sid, ctrl, x, y, alpha=1.0, sx=1.0):
    c = dict(ctrl)
    c['__noactions__'] = True
    inst = R.Instance(X, sid, ctrl=c)
    rd = R.Renderer(X, K)
    cmds = []
    M = dict(a=sx, b=0, c=0, d=1, tx=0, ty=0)
    rd.collect(inst, M, R.NOCX, set(), cmds)
    b = rd.bounds(cmds)
    ox, oy = b[0] - 1, b[1] - 1
    Wz, Hz = int((b[2] - b[0] + 2) * X.Z) + 1, int((b[3] - b[1] + 2) * X.Z) + 1
    cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
    rd.draw(cmds, cv, (ox, oy))
    im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    im = im.resize((max(1, int(round(Wz * K / X.Z))), max(1, int(round(Hz * K / X.Z)))), Image.LANCZOS).convert('RGBA')
    if alpha < 1:
        im.putalpha(im.split()[3].point(lambda v: int(v * alpha)))
    canvas.alpha_composite(im, (int(round(x * K + ox * K)), int(round(y * K + oy * K))))


canvas = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
draw(canvas, Gd, 10, {}, 0, 0)                      # mcBg
draw(canvas, Gq, 3, {3: 1}, 0, 230)                 # mcGroundLimit
# the grid of the thumbnail: column heights and colours (gem frame: colour + 1, + 10 frozen), y = 0 above the line
GRID = [[1, 2, 2, 3], [3, 2, 1], [2, 1, 1, 12, 3], [1, 3], [2, 2, 1], [3, 1], [1, 3, 3, 2], [2, 12, 1], [3, 2], [1, 1, 3, 2]]
rs = 7
for x, col in enumerate(GRID):
    for y, f in enumerate(col):
        rs = (rs * 1103515245 + 12345) & 0x7fffffff
        draw(canvas, G, 201, {201: 1, 197: f}, 30 + (x + 0.5) * 24, 230 - (y + 0.5) * 24, alpha=(45 + (rs >> 16) % 45) / 100)
# the penguins (the chick at both ends, like the thumbnail) and the balls they carry
BODY = [40, 1, 13, 1, 31, 10, 1, 27, 16, 40]
CARRY = {2: 1, 5: 1, 7: 2}
for x in range(10):
    if x in CARRY:
        draw(canvas, G, 201, {201: 1, 197: CARRY[x]}, 30 + (x + 0.5) * 24, 282 - 8 + (7 if BODY[x] == 40 else 0), alpha=0.8)
for x in range(10):
    b = BODY[x]
    lim = 15 if b == 40 else 1
    draw(canvas, G, 83, {83: 1, 59: b, 61: lim, 65: lim, 45: 1}, 30 + (x + 0.5) * 24, 300)
draw(canvas, Gd, 4, {}, 0, 0)                       # mcCache (window frame)

# title band of the old thumbnail (176 px wide), enlarged, with feathered top and bottom edges
old = Image.open(os.path.join(REPO, 'public/assets/img/gfx/artwork/old/paradice.gif')).convert('RGB')
k = 600 / old.width
y0, y1 = 73, 112                                    # band rows in the thumbnail (the title, without the gems above and below)
band = old.crop((0, y0, old.width, y1)).resize((600, int(round((y1 - y0) * k))), Image.LANCZOS).convert('RGBA')
h = band.height
mask = Image.new('L', (600, h), 0)
m = np.zeros((h, 600), dtype=np.float32)
for yy in range(h):
    e = min(yy, h - 1 - yy) / (h * 0.22)
    m[yy, :] = min(1.0, max(0.0, e))
mask = Image.fromarray((m * 255).astype(np.uint8), 'L')
band.putalpha(mask)
canvas.alpha_composite(band, (0, int(round(y0 * k))))
out = os.path.join(REPO, 'public/assets/img/gfx/artwork/paradice.jpg')
canvas.convert('RGB').save(out, quality=92)
print(out)
