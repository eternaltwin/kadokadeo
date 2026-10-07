"""Start screen of Puzzle-Manda (600 x 600), composed from SWF renders after the old thumbnail
(public/assets/img/gfx/artwork/old/puzzlemanda.gif: big fruits filling the picture; its handwritten title is not in
the SWF): the background of the game, its grid panel, a 6 x 6 grid of fruits (and a bonus) at 167 % (a fixed random),
the snake winding through them (pieces of body of the cells, its head eating a fruit: partOnde) and a few pieces of
fruit.
usage: puzzlemanda_artwork.py <out dir of puzzlemanda_assets.py (unused)> <artwork.jpg>"""
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'puzzlemanda', '')
DST = sys.argv[2]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
G.blur_filters = True
rnd = random.Random(11)

# cell frames of the snake's body: the two sides each piece joins (Cell.displaySnake)
HORI, VERT, BOTTOM_RIGHT, BOTTOM_LEFT, TOP_RIGHT, TOP_LEFT = 60, 61, 62, 63, 64, 65


def M(a=1, b=0, c=0, d=1, tx=0, ty=0):
    return dict(a=a, b=b, c=c, d=d, tx=tx, ty=ty)


cmds = []


def put(sid, m, ctrl=None, cx=R.NOCX):
    c = dict(ctrl or {})
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    R.Renderer(G, 2).collect(inst, m, cx, set(), cmds)


S = 50 / 30.0          # 6 cells of 50 px (Flash pixels of a 300 x 300 picture) instead of 30


def cell_xy(x, y):
    return 25 + 50 * x, 25 + 50 * y


# the background without its time bar (depths 5 and 8), its dark part only, and the grid panel ("back", 100 x 100
# scaled like Game.initGrid) over all of it
sd = G.sprites[59]
nd = R.SpriteDef(100059, sd.nframes)
nd.labels, nd.actions = dict(sd.labels), dict(sd.actions)
nd.frames = [[(k, v) for k, v in ops if not (k == 'place' and v.get('depth') in (5, 8))] for ops in sd.frames]
G.sprites[100059] = nd
put(100059, M(1.3, 0, 0, 1.3, 0, -75))
put(34, M(3.0, 0, 0, 3.0, 0, 0))
# the snake: tail at (0, 4), head at (4, 2) going right
path = [(0, 4), (1, 4), (1, 3), (2, 3), (3, 3), (3, 2)]
body = {(0, 4): HORI, (1, 4): TOP_LEFT, (1, 3): BOTTOM_RIGHT, (2, 3): HORI, (3, 3): TOP_LEFT, (3, 2): BOTTOM_RIGHT}
head = (4, 2)
fruits = []
for y in range(6):
    for x in range(6):
        if (x, y) in body or (x, y) == head:
            continue
        s = rnd.randrange(5) + 1
        if (x, y) == (1, 1):
            s = 6          # a bonus (its stars)
        if (x, y) == (5, 4):
            s = 8          # the 15000 bonus (ColorMatrixFilter)
        fruits.append(((x, y), s))
for (x, y), s in fruits:
    px, py = cell_xy(x, y)
    put(52, M(S, 0, 0, S, px, py), {52: 1, 44: s, 42: 1})
for (x, y) in path:
    px, py = cell_xy(x, y)
    put(52, M(S, 0, 0, S, px, py), {52: body[(x, y)]})
hx, hy = cell_xy(*head)
put(3, M(S * 0.75, 0, 0, S * 0.75, hx + 6, hy), {3: 2}, cx=dict(mult=[1.0, 1.0, 1.0, 0.5], add=[0, 0, 0, 0]))
# the head looks a little up, towards the next fruit
a = math.radians(-12)
put(30, M(S * math.cos(a), S * math.sin(a), -S * math.sin(a), S * math.cos(a), hx - 4, hy))
# pieces of the fruit eaten (partFruit, frame of the orange), spread around the head
for i in range(5):
    t = rnd.random() * 6.28
    r = 24 + rnd.random() * 10
    sc = 1.0 + rnd.random() * 0.4
    rot = rnd.random() * 6.28
    put(12, M(sc * math.cos(rot), sc * math.sin(rot), -sc * math.sin(rot), sc * math.cos(rot), hx + math.cos(t) * r, hy + math.sin(t) * r), {12: 2})

Z = G.Z
cv = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
R.Renderer(G, 2).draw(cmds, cv, (0, 0))
im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
im = im.resize((600, 600), Image.LANCZOS)
bg = Image.new('RGBA', (600, 600), (255, 255, 255, 255))
bg.alpha_composite(im)
bg.convert('RGB').save(DST, quality=92)
print('artwork', DST)
