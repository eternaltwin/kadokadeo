"""Start screen of Toy Maniak (public/assets/img/gfx/artwork/toymaniak.jpg, 600 x 600) composed from the pictures of
toymaniak_assets.py (SWF renders), placed as the game places them, after the old thumbnail (artwork/old/toymaniak.gif:
the crushers with gifts, a counter, toys on the belts, the box; its "Toy Maniak" logo is not in the SWF): the decor,
the 3 rails with toys of every kind and the bonuses, a cruncher down on a toy, gifts going out, the counters coloured by
their combo with a light on, the box with toys in 2 slots and a toy in hand over the third.
usage: toymaniak_artwork.py <out dir of toymaniak_assets.py> <out jpg>"""
import os, sys, json
import numpy as np
from PIL import Image

OUT, DST = sys.argv[1], sys.argv[2]
SRC = os.path.join(OUT, 'src')
piv = json.load(open(os.path.join(OUT, 'pivots.json')))
meta = json.load(open(os.path.join(OUT, 'meta.json')))
K = 2
TOYS = [1, 4, 5, 2, 6, 8, 9]
COLORS = [0xFFCC00, 0xFFFFFF, 0x92BBDA, 0x7BE425]


def pic(anim, frame=1):
    return Image.open(os.path.join(SRC, anim, '%d.png' % frame)).convert('RGBA')


def layer(anim, frame, x, y, sx=1.0, sy=1.0, res=K, tint=None):
    """the picture of anim on a 600 x 600 transparent layer, its pivot at Flash position (x, y)"""
    im = pic(anim, frame)
    if tint is not None:
        a = np.asarray(im, dtype=np.float32)
        a[..., 0] *= ((tint >> 16) & 255) / 255.0
        a[..., 1] *= ((tint >> 8) & 255) / 255.0
        a[..., 2] *= (tint & 255) / 255.0
        im = Image.fromarray(a.astype(np.uint8), 'RGBA')
    px, py = piv[anim][0] * im.width, piv[anim][1] * im.height
    s_x, s_y = sx * K / res, sy * K / res
    if (s_x, s_y) != (1, 1):
        im = im.resize((max(1, round(im.width * s_x)), max(1, round(im.height * s_y))), Image.BICUBIC)
        px, py = px * s_x, py * s_y
    out = Image.new('RGBA', (600, 600), (0, 0, 0, 0))
    out.alpha_composite(im, (int(round(x * K - px)), int(round(y * K - py))))
    return out


def put(canvas, *a, **k):
    canvas.alpha_composite(layer(*a, **k))


def toy_layer(frame, x, y):
    f = meta['toyFrames'][frame - 1]
    n, tx, ty, sx, sy = f
    return layer('toy%d' % n, 1, x + tx, y + ty, sx, sy, meta['toyRes'][n])


canvas = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
put(canvas, 'bg', 1, 0, 0)
# the box and its slots: toys in s0 and s2 (frame 16), s1 empty (frame 1); the toys under the slot's mask
BX, BY = 150, 300
put(canvas, 'box', 1, BX, BY)
mask_full = None
slots = meta['slots']
for name, toyframe in (('s1', None), ('s2', TOYS[2]), ('s0', TOYS[0])):
    sx_, sy_, _ = slots[name]
    x, y = BX + sx_, BY + sy_
    put(canvas, 'slot', 1, x, y)
    f = 16 if toyframe else 1
    inner = layer('slotBar', 1, x + meta['slot']['barX'], y + meta['slot']['bar'][f - 1])
    if toyframe:
        inner.alpha_composite(toy_layer(toyframe, x + meta['slot']['toyX'], y + meta['slot']['toy'][f - 1]))
    m = np.asarray(layer('slotMask', 1, x, y), dtype=np.float32)[..., 3:4] / 255.0
    a = np.asarray(inner, dtype=np.float32)
    a[..., 3:4] *= m
    canvas.alpha_composite(Image.fromarray(a.astype(np.uint8), 'RGBA'))
# the rails: (toys: [frame, x]), the counter (value, colour), the light frame, the cruncher y
RAILS = [
    dict(toys=[(7, 27), (TOYS[1], 77), (TOYS[1], 127), (TOYS[4], 177), (TOYS[1], 227), (TOYS[2], 277)], combo='014',
         last=1, green=4, cruncher=-50),
    # (a truck under the cruncher: Toy.update lowers it to -50 + p * 35 as the toy comes to the end of the rail)
    dict(toys=[(7, -9), (TOYS[2], 41), (TOYS[6], 91), (TOYS[2], 141), (TOYS[2], 191), (TOYS[3], 241), (TOYS[2], 291)],
         combo='037', last=2, green=1, cruncher=-50 + 0.7 * 35),
    dict(toys=[(7, 16), (TOYS[0], 66), (TOYS[5], 116), (TOYS[0], 166), (3, 216), (TOYS[0], 266)], combo='009', last=0,
         green=6, cruncher=-50),
]
for r, rail in enumerate(RAILS):
    y = 70 + 75 * r
    put(canvas, 'back', 1, 300, y)
    dx = meta['digits']
    xx = dx['x']
    for ch in rail['combo']:
        d = int(ch)
        put(canvas, 'digit', d + 1, 300 + xx, y + dx['base'], tint=COLORS[rail['last']])
        xx += dx['adv'][d]
    lg = meta['lights']
    put(canvas, 'green', rail['green'], 300 + lg['green']['x'], y + lg['green']['y'])
    put(canvas, 'red', 1, 300 + lg['red']['x'], y + lg['red']['y'])
for r, rail in enumerate(RAILS):
    y = 70 + 75 * r
    for frame, x in rail['toys']:
        canvas.alpha_composite(toy_layer(frame, x, y))
for r, rail in enumerate(RAILS):
    y = 70 + 75 * r
    fr = meta['front']
    put(canvas, 'front', 1, 300, y)
    put(canvas, 'tread0', 1, 300 - 303, y + fr['t0'][1], res=1)
    put(canvas, 'tread1', 1, 300 - 305, y + fr['t1'][1], res=1)
    # the cruncher through the rectangle of shape 51
    c = np.asarray(layer('cruncher', 1, 300 + fr['cruncher'][0], y + rail['cruncher']), dtype=np.float32)
    mx0, mx1, my0, my1 = fr['mask']
    keep = np.zeros(c.shape[:2] + (1,), dtype=np.float32)
    keep[int(round((y + my0) * K)):int(round((y + my1) * K)), int(round((300 + mx0) * K)):int(round((300 + mx1) * K))] = 1
    c[..., 3:4] *= keep
    canvas.alpha_composite(Image.fromarray(c.astype(np.uint8), 'RGBA'))
    put(canvas, 'frontEnd', 1, 300, y)
# a toy in hand over the empty slot (the snake, centred on its bounds like Game.updateCursor)
b = meta['toyBounds'][TOYS[3] - 1]
mx, my = 158, 262
canvas.alpha_composite(toy_layer(TOYS[3], mx - (b[0] + b[1]) / 2, my - (b[2] + b[3]) / 2 - 10))
canvas.convert('RGB').save(DST, quality=92)
print(DST)
