"""Start screen of Memopsy (public/assets/img/gfx/artwork/memopsy.jpg, 600 x 600) composed from the pictures of
memopsy_assets.py (SWF renders only), placed after the old thumbnail (artwork/old/memopsy.gif): the brown decor with
the big circles in the upper left, and a grid of cards tilted about 10 degrees, most face down, a few showing the
leaf, the spoon, the book and the amethyst; the thumbnail's "Memo-Psy" logo is not in the SWF, so it is not drawn.
usage: memopsy_artwork.py <out dir of memopsy_assets.py> <out jpg> [games list png (176 x 106)]"""
import os, sys, json, math
from PIL import Image

OUT, DST = sys.argv[1], sys.argv[2]
PNG = sys.argv[3] if len(sys.argv) > 3 else None
SRC = os.path.join(OUT, 'src')
piv = json.load(open(os.path.join(OUT, 'pivots.json')))
K = 2


def pic(anim, frame=1):
    return Image.open(os.path.join(SRC, anim, '%d.png' % frame)).convert('RGBA')


def put(canvas, anim, frame, x, y, rot=0.0, scale=1.0):
    """the picture of anim composed with its pivot at (x, y) of the canvas, turned by rot degrees around the pivot"""
    im = pic(anim, frame)
    px, py = piv[anim][0] * im.width, piv[anim][1] * im.height
    if scale != 1.0:
        im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
        px, py = px * scale, py * scale
    if rot:
        w, h = im.size
        im = im.rotate(rot, Image.BICUBIC, expand=True)
        # the pivot turned around the picture centre (PIL turns counter-clockwise and recentres the expanded picture)
        a = math.radians(rot)
        cx, cy = w / 2.0, h / 2.0
        dx, dy = px - cx, py - cy
        px = im.width / 2.0 + dx * math.cos(a) + dy * math.sin(a)
        py = im.height / 2.0 - dx * math.sin(a) + dy * math.cos(a)
    canvas.alpha_composite(im, (int(round(x - px)), int(round(y - py))))


canvas = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
put(canvas, 'bg', 1, 0, 0)
# the circles like the thumbnail: centred in the upper left, turned a little
put(canvas, 'bgAnim', 1, 210, 190, rot=25)

# the card grid of the thumbnail: big cards (the thumbnail is a zoomed crop), tilted about 10 degrees, cut by the
# edges; 1 the back, 4 leaf, 5 book, 6 spoon, 7 amethyst
A = math.radians(10)
S = 1.6
DXx, DXy = 162 * math.cos(A), -162 * math.sin(A)
DYx, DYy = 205 * math.sin(A), 205 * math.cos(A)
OX, OY = 20, 10
FACES = {(1, 0): 4, (2, 1): 6, (3, 1): 4, (1, 2): 5, (2, 2): 7}
for row in range(-1, 4):
    for col in range(-1, 5):
        x = OX + col * DXx + row * DYx
        y = OY + col * DXy + row * DYy
        if x < -140 or x > 740 or y < -180 or y > 780:
            continue
        put(canvas, 'card', FACES.get((col, row), 1), x, y, rot=10, scale=S)

canvas.convert('RGB').save(DST, quality=92)
print(DST)

# the 176 x 106 thumbnail of the games list (image_path of GameSeeder.php), a band of the same picture
if PNG:
    band = canvas.crop((0, 102, 600, 102 + int(600 * 106 / 176))).resize((176, 106), Image.LANCZOS)
    band.convert('RGB').save(PNG, optimize=True)
    print(PNG)
