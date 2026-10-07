"""The bonuses rendered from the SWF next to the port's (pbonus.mjs): in the grid (cell frame 40, symbol 6..8: the stars
at their placed rotation, the port's turn) and blinking (cell frame 17, its copy `mc` blurred in "add" at 50 %), each
x3. usage: pbonus.py <out.png>"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'puzzlemanda', '')
D = W + 'check/bonus/'
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
G.blur_filters = True
BG = (0x6a, 0x2b, 0x8a)


def swf(frame, sym, bg):
    inst = R.Instance(G, 52, ctrl={'__noactions__': True, 52: frame, 44: sym, 'mc': sym, 42: 1})
    cmds = []
    R.Renderer(G, 2).collect(inst, dict(a=1, b=0, c=0, d=1, tx=20, ty=20), R.NOCX, set(), cmds)
    cv = np.zeros((40 * G.Z, 40 * G.Z, 4), dtype=np.float32)
    R.Renderer(G, 2).draw(cmds, cv, (0, 0))
    im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA').resize((80, 80), Image.LANCZOS)
    out = bg.copy().convert('RGBA')
    out.alpha_composite(im)
    return out.convert('RGB')


rows = []
for t in (1, 2, 3):
    g = Image.open(D + 'b%d_grid.png' % t).convert('RGB')
    port_cell = g.crop((330 - 40, 390 - 40, 330 + 40, 390 + 40))
    # the background under the cell, from the port's picture of the same place on the first frame (the grid panel)
    bgc = Image.new('RGB', (80, 80), g.getpixel((330 - 39, 390 - 39)))
    blinks = [Image.open(D + 'b%d_blink%d.png' % (t, i)).convert('RGB').crop((0, 0, 600, 110)) for i in range(4)]
    rows.append((t, swf(40, 5 + t, bgc), port_cell, swf(17, 5 + t, Image.new('RGB', (80, 80), blinks[0].getpixel((5, 5)))), blinks))
Z = 3
out = Image.new('RGB', (80 * Z * 3 + 40, len(rows) * (80 * Z + 130 + 30)), (233, 249, 255))
dr = ImageDraw.Draw(out)
y = 0
for t, s, p, sb, blinks in rows:
    dr.text((4, y + 2), 'bonus %d: SWF (stars unturned) | port in the grid | SWF blinking (frame 17)        then the port\'s sequence, 4 moments' % t, fill=(0, 0, 0))
    for j, im in enumerate((s, p, sb)):
        out.paste(im.resize((80 * Z, 80 * Z), Image.LANCZOS), (j * (80 * Z + 20), y + 16))
    y += 80 * Z + 20
    for i, bl in enumerate(blinks[:2]):
        out.paste(bl.resize((360, 66), Image.LANCZOS), (i * 380, y))
    y += 66 + 64
out.save(sys.argv[1])
print(out.size)
