"""The comparison pages of Game.debugShow drawn from the SWF (swfrender): $KKP_WORK/memopsy/check/ref<page>.png, to
compare with the game's screenshots (mpage.mjs -> run<page>.png) with tools/cmp_pages.py. The clips are placed as
debugShow places them.
usage: python3 ref.py"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'memopsy', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, 2)


def M(tx=0.0, ty=0.0, rot=0.0):
    a = math.radians(rot)
    return dict(a=math.cos(a), b=math.sin(a), c=-math.sin(a), d=math.cos(a), tx=tx, ty=ty)


def page(items):
    cmds = []
    for sid, frame, m, ctrl in items:
        i = R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))
        i.goto_and_stop(frame)
        RD.collect(i, m, R.NOCX, set(), cmds)
    can = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
    RD.draw(cmds, can, (0, 0))
    im = Image.fromarray(np.clip(can * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
    out = Image.new('RGBA', im.size, (0, 0, 0, 255))
    out.alpha_composite(im)
    return out.resize((600, 600), Image.LANCZOS).convert('RGB')


D = os.path.join(W, 'check')
os.makedirs(D, exist_ok=True)

# page 0: the 11 frames of the card, the 9 of the flip (top on frame 8, back stopped on 1), the 5 of the good flash,
# the 2 life beads (Game.debugShow)
p0 = [(40, 1, M(), None)]
for k in range(11):
    p0.append((25, k + 1, M(4 + 50 * (k % 6), 6 if k < 6 else 78), None))
for k in range(9):
    p0.append((26, k + 1, M(4 + 33 * k, 150), {'top': 8, 'back': 1}))
for k in range(5):
    p0.append((32, k + 1, M(8 + 50 * k, 222), None))
for k in range(2):
    p0.append((36, k + 1, M(260 + 16 * k, 230), None))
page(p0).save(os.path.join(D, 'ref0.png'))

# page 1: the start of a game (bg, bgAnim turned 30 degrees, the 4 x 2 grid with one face, the 10 lives)
p1 = [(40, 1, M(), None), (38, 1, M(150, 150, 30), None)]
px = (300 - 4 * 50 + 8) / 2
py = (290 - 2 * 70 + 6) / 2 + 10
for x in range(4):
    for y in range(2):
        p1.append((25, 5 if (x, y) == (1, 1) else 1, M(px + x * 50, py + y * 70), None))
for k in range(10):
    p1.append((36, 1, M(150 - 0.5 * 20 * 13 + k * 13, 2), None))
page(p1).save(os.path.join(D, 'ref1.png'))
print(D)
