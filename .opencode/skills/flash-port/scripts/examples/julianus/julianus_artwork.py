"""Start screen of Julianus (public/assets/img/gfx/artwork/julianus.jpg, 600 x 600) composed from SWF renders, after
the layout of the old thumbnail (artwork/old/julianus.gif): the decor at the start of a game (camera at the top), a
big and a small bubble, the hero looking up, a spike ball and the green bonus, the characters 1.6 times bigger than in
the game like the thumbnail (rendered at that size by julianus_assets.py: out/art). The handwritten title of the
thumbnail is not in the SWF: left out.
usage: julianus_artwork.py <out dir of julianus_assets.py> <out jpg>"""
import os, sys, json, math
from PIL import Image

OUT, DST = sys.argv[1], sys.argv[2]
SRC = os.path.join(OUT, 'src')
ART = os.path.join(OUT, 'art')
meta = json.load(open(os.path.join(OUT, 'meta.json')))
reg = json.load(open(os.path.join(ART, 'reg.json')))
K = 2
canvas = Image.new('RGBA', (300 * K, 300 * K), (0, 0, 0, 255))


def place(name, x, y, scale=1.0, rot=0.0):
    """the render of out/art at (x, y) Flash pixels, its registration point there, scaled and turned (degrees)"""
    im = Image.open(os.path.join(ART, name + '.png')).convert('RGBA')
    px, py = reg[name]
    if scale != 1:
        im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
        px, py = px * scale, py * scale
    if rot:
        # turned around its registration point: pad so that it is the centre, then rotate (PIL turns anticlockwise)
        w, h = im.size
        r = int(math.ceil(max(math.hypot(px, py), math.hypot(w - px, py), math.hypot(px, h - py), math.hypot(w - px, h - py))))
        big = Image.new('RGBA', (2 * r, 2 * r))
        big.alpha_composite(im, (int(round(r - px)), int(round(r - py))))
        im = big.rotate(-rot, resample=Image.BICUBIC)
        px = py = r
    canvas.alpha_composite(im, (int(round(x * K - px)), int(round(y * K - py))))


# decor: the 3 planes at x = 0, camera at the top (the bitmaps at 1 px per Flash pixel, drawn x2)
for name in ('bg2', 'bg1', 'bg0'):
    for an, x, y in meta['decor'][name]['parts']:
        im = Image.open(os.path.join(SRC, an, '1.png')).convert('RGBA')
        im = im.resize((im.width * K, im.height * K), Image.BILINEAR)
        canvas.alpha_composite(im, (int(x * K), int(y * K)))
# (positions of the thumbnail; the bubbles at 47 % and 30 %, as in the game)
place('bulle', 180, 92, scale=0.47 / 1.6)
place('bulle', 258, 128, scale=0.3 / 1.6)
# the hero looking up: body turned -90 degrees (ang = -PI / 2), eyes frame 46
s = 1.6
place('body', 145 + meta['body'][0] * s, 196 + meta['body'][1] * s, rot=-90)
place('eyes', 145, 196)
place('pic0', 229, 213)
place('bonus0', 230, 264)
canvas.convert('RGB').save(DST, quality=92)
print('artwork', DST)
