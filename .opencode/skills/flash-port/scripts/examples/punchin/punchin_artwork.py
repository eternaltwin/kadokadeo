"""Start screen of Punch-In (public/assets/img/gfx/artwork/punchin.jpg, 600 x 600) composed from SWF renders, after the
layout of the old thumbnail (artwork/old/punchin.gif): the ring (mcBg), the afro in front on the right (mcAfro, a frame
of his stand), the player from behind at the bottom left (mcPlayer), and the title "PUNCH IN !" in the font embedded in
the SWF (Verdana Bold Italic, font 53: the SWF has no title picture), orange with a dark outline like the thumbnail's.
usage: punchin_artwork.py <out jpg>"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'punchin', '')
DST = sys.argv[1]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z

canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)


def comp(layer):
    global canvas
    canvas *= (1 - layer[..., 3:4])
    canvas += layer


def draw(sid, frame, x, y, sx=1.0, sy=None):
    inst = R.Instance(G, sid, ctrl={'__noactions__': True, sid: frame})
    cmds = []
    rd = R.Renderer(G, Z)
    rd.collect(inst, dict(R.IDENT, a=sx, d=sy if sy is not None else abs(sx), tx=x, ty=y), R.NOCX, set(), cmds)
    layer = np.zeros_like(canvas)
    rd.draw(cmds, layer, (0, 0))
    comp(layer)


# the ring, where the game puts it (bg._x = Cs.w / 2 + 40, bg._y = Cs.h)
draw(105, 1, 190, 300)
# the afro, bigger, on the right (stand)
draw(47, 8, 205, 345, 1.18)
# the player from behind, bottom left (frame 1 of his stand)
draw(96, 1, 95, 345, 1.05)

img = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
img = img.resize((600, 600), Image.LANCZOS)
bg = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
bg.alpha_composite(img)

# the title: two lines, orange letters with a dark brown outline and a light rim, slightly rotated like the thumbnail's
FONT = W + 'fonts_gfx/53_Verdana.ttf'
title = Image.new('RGBA', (600, 600), (0, 0, 0, 0))
d = ImageDraw.Draw(title)
for text, (x, y), size in (('PUNCH', (36, 40), 92), ('IN !', (78, 140), 92)):
    f = ImageFont.truetype(FONT, size)
    d.text((x, y), text, font=f, fill=(255, 120, 20, 255), stroke_width=9, stroke_fill=(70, 25, 5, 255))
    d.text((x, y), text, font=f, fill=(255, 132, 24, 255), stroke_width=3, stroke_fill=(255, 210, 120, 255))
    d.text((x, y), text, font=f, fill=(255, 120, 20, 255))
title = title.rotate(4, resample=Image.BICUBIC, center=(200, 140))
shadow = Image.new('RGBA', (600, 600), (0, 0, 0, 0))
shadow.putalpha(title.split()[3].filter(ImageFilter.GaussianBlur(6)).point(lambda v: v * 0.6))
bg.alpha_composite(shadow, (4, 6))
bg.alpha_composite(title)
bg.convert('RGB').save(DST, quality=92)
print(DST)
