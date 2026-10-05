"""Start screen of Schizo Fuzz (public/assets/img/gfx/artwork/schizofuzz.jpg, 600 x 600) composed from SWF renders, after
the layout of the old thumbnail (artwork/old/schizofuzz.gif: the squirrel flying up from a springboard in the forest;
its "Schizo Fuzz" title is not in the SWF and is not redrawn): the decor planes where the game places them, a tree,
a springboard and the hero, drawn at their native resolution (bitmaps) or rendered from the shapes (vectors).
usage: schizofuzz_artwork.py <out jpg>"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'schizofuzz', '')
G = R.SWF(W + '_gfx.swf', W + 'shp4__gfx', Z=4)
Gp = R.SWF(W + '_gfx.swf', W + 'shp1__gfx', Z=1)
for X in (G, Gp):
    X.flash_replace = True
    X.lighten = True
K = 2


def draw(canvas, X, sid, ctrl, x, y, sc=1.0, rot=0.0):
    """the symbol `sid` placed at (x, y) Flash pixels of the game, scaled and turned (degrees)"""
    c = dict(ctrl)
    c[sid] = c.get(sid, 1)
    c['__noactions__'] = True
    inst = R.Instance(X, sid, ctrl=c)
    r = math.radians(rot)
    M = dict(a=sc * math.cos(r), b=sc * math.sin(r), c=-sc * math.sin(r), d=sc * math.cos(r), tx=0, ty=0)
    rd = R.Renderer(X, K)
    cmds = []
    rd.collect(inst, M, R.NOCX, set(), cmds)
    b = rd.bounds(cmds)
    ox, oy = b[0] - 6, b[1] - 6
    Wz, Hz = int((b[2] - b[0] + 12) * X.Z) + 1, int((b[3] - b[1] + 12) * X.Z) + 1
    cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
    rd.draw(cmds, cv, (ox, oy))
    im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    im = im.resize((int(round(Wz * K / X.Z)), int(round(Hz * K / X.Z))), Image.LANCZOS).convert('RGBA')
    canvas.alpha_composite(im, (int(round((x + ox) * K)), int(round((y + oy) * K))))


canvas = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
# Game.new: bg_plan5 at 0, the others from the bottom of their area (BG_HEIGHT: 31, 50, 215, 221, 85), back to front
draw(canvas, Gp, Gp.sid('bg_plan5'), {}, 0, 0)
draw(canvas, Gp, Gp.sid('bg_plan4'), {}, -60, 170 - 85)
draw(canvas, Gp, Gp.sid('bg_plan3'), {}, -150, 290 - 221)
draw(canvas, Gp, Gp.sid('bg_plan2'), {}, -40, 300 - 215)
draw(canvas, Gp, Gp.sid('bg_plan1'), {}, -100, 300 - 50)
draw(canvas, Gp, 201, {201: 2}, 230, 310)                       # a tree (bgItem), at BOTTOM + 30
draw(canvas, G, 103, {103: 3, 65: 1}, 75, 280)                 # the springboard (item 2), at BOTTOM
draw(canvas, G, 153, {153: 1, 'sub': 1}, 140, 150, 2.0, -28)    # the hero flying up
draw(canvas, Gp, Gp.sid('bg_plan0'), {}, -20, 300 - 31)
canvas.convert('RGB').save(sys.argv[1], quality=90)
print(sys.argv[1])
