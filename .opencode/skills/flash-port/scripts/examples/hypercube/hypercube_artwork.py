"""Start screen of Hypercube (public/assets/img/gfx/artwork/hypercube.jpg, 600 x 600) composed from the pictures of
hypercube_assets.py (SWF renders), placed as the game places them, after the old thumbnail (artwork/old/hypercube.gif:
a board covered with forms of the 3 colours; its "Hypercube" logo is not in the SWF): the decor, the conveyor with its
stripes, 3 pieces on it and the time ring, the board covered with forms (a special cube among them), a square just
scored (its dotted square, its score and the last particles of its cubes) and a piece in hand.
usage: hypercube_artwork.py <out dir of hypercube_assets.py> <out jpg>"""
import os, sys, json, random
from PIL import Image, ImageEnhance

OUT, DST = sys.argv[1], sys.argv[2]
SRC = os.path.join(OUT, 'src')
piv = json.load(open(os.path.join(OUT, 'pivots.json')))
meta = json.load(open(os.path.join(OUT, 'meta.json')))
K = 2
SIZE = 15
rng = random.Random(7)
DIR = [(1, 0), (0, 1), (-1, 0), (0, -1)]


def pic(anim, frame=1):
    return Image.open(os.path.join(SRC, anim, '%d.png' % frame)).convert('RGBA')


def put(canvas, anim, frame, x, y, scale=1.0, alpha=1.0, res=K):
    """the picture of anim at Flash position (x, y), scaled (texture `res` px per Flash px)"""
    im = pic(anim, frame)
    s = scale * K / res
    if s != 1:
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
    if alpha < 1:
        a = im.split()[3].point(lambda v: round(v * alpha))
        im.putalpha(a)
    px, py = piv[anim]
    canvas.alpha_composite(im, (round(x * K - px * im.width), round(y * K - py * im.height)))


canvas = Image.new('RGBA', (600, 600))
canvas.alpha_composite(pic('bg').resize((600, 600), Image.BILINEAR))
r = meta['ray']
put(canvas, 'ray', 1, r['x'] - 7, r['y'], alpha=r['alpha'] / 100, res=1)
h = meta['horloge']
put(canvas, 'ha', 1 + 40, h['x'], h['y'], alpha=h['alpha'] / 100, res=h['res'])


def subframe(cells, c):
    f = 1
    for n, (dx, dy) in enumerate(DIR):
        if (c[0] + dx, c[1] + dy) in cells:
            f += 2 ** n
    return f


def cube(canvas, x, y, col, sub, light=False, scale=1.0):
    put(canvas, 'cube%d' % col, sub, x, y, scale)
    if light:
        put(canvas, 'cubLight', 1, x + meta['cubLight']['x'] * scale, y + meta['cubLight']['y'] * scale, scale)


def piece(cells, col, ox, oy, lights=()):
    """cubes of a piece (cells relative to the piece's centre, Piece.build) in the order of their list"""
    cs = set(cells)
    for c in sorted(cells):
        cube(canvas, ox + c[0] * SIZE, oy + c[1] * SIZE, col, subframe(cs, c), c in lights)


# the conveyor: 3 pieces (y = SIZE * 2.5), centred on their cells
piece([(-0.5, -1), (-0.5, 0), (-0.5, 1), (0.5, 1)], 2, 52, 37.5)
piece([(-1, 0), (0, 0), (1, 0), (0, -1)], 1, 220, 37.5)
piece([(0, -0.5), (0, 0.5)], 0, 285, 37.5)

# the board: forms grown at random over cells (1..18, 6..18), drawn in depth order (x * 100 + y)
grid = {}
forms = []
cells_free = [(x, y) for x in range(1, 19) for y in range(6, 19)]
SKIP = {(x, y) for x in range(8, 12) for y in range(10, 14)}      # the square being scored
for x in range(3, 7):
    for y in range(6, 9):
        SKIP.add((x, y))                                           # where the piece in hand goes
rng.shuffle(cells_free)
for c0 in cells_free:
    if c0 in grid or c0 in SKIP or rng.random() < 0.18:
        continue
    size = rng.choice([1, 2, 3, 3, 4, 4, 5])
    cells = [c0]
    for _ in range(40):
        if len(cells) >= size:
            break
        bx, by = rng.choice(cells)
        dx, dy = rng.choice(DIR)
        n = (bx + dx, by + dy)
        if 1 <= n[0] <= 18 and 6 <= n[1] <= 18 and n not in grid and n not in cells and n not in SKIP:
            cells.append(n)
    col = rng.randrange(3)
    for c in cells:
        grid[c] = (col, len(forms))
    forms.append(cells)
light = sorted(grid)[len(grid) // 3]
for x in range(20):
    for y in range(20):
        if (x, y) in grid:
            col, fi = grid[(x, y)]
            cube(canvas, (x + 0.5) * SIZE, (y + 0.5) * SIZE, col, subframe(set(forms[fi]), (x, y)), (x, y) == light)

# the square being scored: its dotted square and score (under the cubes), cubes of 2 forms shrinking
sq = meta['square']
put(canvas, 'squareBg', 1, 8 * SIZE + sq['bgx'], 10 * SIZE + sq['bgy'], scale=4 * SIZE / 100)
dg = meta['digits']
s = 4 * SIZE * 0.5
sc = min(4 * 20, 100) / 100
text = '1200'
width = sum(dg['adv'][int(ch)] for ch in text)
pen = dg['x0'] + (dg['x1'] - dg['x0'] - width) * 0.5
for ch in text:
    put(canvas, 'digit', int(ch) + 1, 8 * SIZE + s + pen * sc, 10 * SIZE + s + dg['base'] * sc, scale=sc)
    pen += dg['adv'][int(ch)]
for i in range(7):
    put(canvas, 'partLight', 1, 120 + 60 * rng.random(), 150 + 60 * rng.random(), scale=0.4 + 0.8 * rng.random(), res=2 * K)

# the piece in hand, over the board (Piece.build: centred on the mouse)
piece([(-1, -0.5), (0, -0.5), (0, 0.5), (1, 0.5)], 1, 75, 110, lights={(0, 0.5)})

out = canvas.convert('RGB')
out.save(DST, quality=92)
print('artwork', DST, out.size)
