"""Start screen of Digestomax (public/assets/img/gfx/artwork/digestomax.jpg, 600 x 600) composed from SWF renders: a
moment of a game as the code places it (there is no old thumbnail of the game: the layout follows the screenshots of
the archive, sc/sc*.jpg, without the interface): the jungle (mcBg), the ground bitmap (the tiles of digestomax_assets.py,
1 px per Flash pixel, zoomed), the fruits of the grid at Cs.getX / getY in the map (map._y = 14), a few special fruits,
and Pioupiou on top of a pile (frame 1 of his animation).
usage: digestomax_artwork.py <out dir of digestomax_assets.py> <out jpg>"""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'digestomax', '')
OUT, DST = sys.argv[1], sys.argv[2]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
pivots = json.load(open(os.path.join(OUT, 'pivots.json')))
MAP_Y = 14
CS, MX, MY = 32, 7 + 16, 0 + 16          # Cs after Cs.init

canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)


def comp(layer):
    global canvas
    canvas *= (1 - layer[..., 3:4])
    canvas += layer


def draw(sid, ctrl, x, y, sx=1.0):
    c = dict(ctrl)
    c.setdefault(sid, 1)
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    cmds = []
    rd = R.Renderer(G, Z)
    rd.collect(inst, dict(R.IDENT, a=sx, tx=x, ty=y), R.NOCX, set(), cmds)
    layer = np.zeros_like(canvas)
    rd.draw(cmds, layer, (0, 0))
    comp(layer)


# the jungle
draw(152, {}, 0, 0)
# the ground: row 0 of the bitmap (mcTile frame 2), its pixels zoomed (the rows below are out of the screen)
tile = Image.open(os.path.join(OUT, 'src', 'tile', '1.png')).convert('RGBA')
px, py = pivots['tile']
ox, oy = px * tile.width, py * tile.height
bmp = Image.new('RGBA', (300, 200), (255, 255, 255, 255))
for x in range(10):
    bmp.alpha_composite(tile, (int(round(x * 32 - ox)), int(round(-oy))))
g = np.asarray(bmp.resize((300 * Z, 200 * Z), Image.NEAREST), dtype=np.float32) / 255.0
layer = np.zeros_like(canvas)
y0 = (MAP_Y + 8 * CS) * Z
layer[y0:, :, :3] = g[:300 * Z - y0, :, :3]
layer[y0:, :, 3] = 1
comp(layer)
# the grid (colours, -1 empty; 20: Pioupiou), from the top row
GRID = [
    "-1 -1 -1 -1 -1 -1 -1 -1 -1",
    "-1 -1 -1 -1 -1 -1 -1 -1 -1",
    "-1 -1 -1 -1 20 -1 -1 -1 -1",
    "-1 -1 -1 -1  3 -1 -1 -1 -1",
    " 3 -1 -1 -1  1  0 -1 -1 12",
    " 1  2 -1  4  0  3  2 -1  1",
    " 0  3  1  2  2  1  0  5  3",
    " 2  0  3  1  0  3  1  2  0",
]
for y, row in enumerate(GRID):
    for x, v in enumerate(int(c) for c in row.split()):
        if v < 0:
            continue
        X, Y = MX + x * CS, MAP_Y + MY + y * CS
        if v == 20:
            # mcBall frame 21, its smc (sprite 146) on frame 1
            draw(148, {148: 21, 146: 1}, X, Y)
        else:
            draw(148, {148: v + 1}, X, Y)

im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGB')
im = im.resize((600, 600), Image.LANCZOS)
im.save(DST, quality=92)
print(DST)
