"""Start screen of Cereal Punk (public/assets/img/gfx/artwork/cerealpunk.jpg, 600 x 600) composed from SWF renders, after
the layout of the old thumbnail (artwork/old/cerealpunk.gif, whose title is not in the SWF): a moment of a game as the
code places it: the barn (bg), the cook on the shelf (column 5, 90 %, holding a peanut), five rows of cereals at the
bottom of the grid (cell x, y at x * 30 + 45, y * 30 - 45) with a gold cereal, a bubble and a cracked stone.
usage: cerealpunk_artwork.py <out jpg>"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cerealpunk', '')
DST = sys.argv[1]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
K = 2
canvas = np.zeros((300 * G.Z, 300 * G.Z, 4), dtype=np.float32)


def draw(name, ctrl, x, y, s=1.0):
    sid = G.sid(name)
    c = dict(ctrl)
    c.setdefault(sid, 1)
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    out = []
    rd = R.Renderer(G, K)
    rd.collect(inst, dict(R.IDENT, a=s, d=s, tx=x, ty=y), R.NOCX, set(), out)
    layer = np.zeros_like(canvas)
    rd.draw(out, layer, (0, 0))
    np.multiply(canvas, 1 - layer[..., 3:4], out=canvas)
    np.add(canvas, layer, out=canvas)


draw('bg', {}, 0, 0)
# the grid: kinds 0..2 (frames id + 1), gold (id + 10), bubble (21), stone (22, cracks sub)
GRID = {7: '0....1..', 8: '12..20.1', 9: '210g1b02', 10: '0s21.012', 11: '12021120'}
for y, row in GRID.items():
    for x, ch in enumerate(row):
        if ch == '.':
            continue
        if ch == 'g':
            f, ct = 12, {}
        elif ch == 'b':
            f, ct = 21, {}
        elif ch == 's':
            f, ct = 22, {'sub': 2}
        else:
            f, ct = int(ch) + 1, {}
        ct[G.sid('legume')] = f
        draw('legume', ct, x * 30 + 45, y * 30 - 45)
# the cook holding a peanut (hands on frame 2, it0 on frame 3)
draw('kanji', {112: 2, 'it0': 3}, 5 * 30 + 45, 65, 0.9)

img = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
img = img.resize((600, 600), Image.LANCZOS).convert('RGB')
img.save(DST, quality=90)
print(DST)
