"""The comparison page of Game.debugShow drawn from the SWF (swfrender): $KKP_WORK/hypercube/check/ref0.png, to compare
with the game's screenshot (hshow.mjs -> run0.png) with tools/cmp_pages.py. The clips are placed as the code places
them, with the colour transforms of Cs.setPercentColor; the texts in the embedded font (score field 30, end text 18)
come from FFDec renders (they draw the embedded glyphs); smc, a Flash Button, is drawn with its over shape (13); the
device-font text of mcScore (BICOLOR / MONOCOLOR) is not drawn (not in the SWF).
usage: python3 ref.py"""
import os, sys, math, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'hypercube', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
FF = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()
for sid, origin, n in ((5, (-46.95, -46.85), 12), (18, (-135.0, -10.2), 1), (30, (-63.1, -17.51), 1)):
    d = W + 'spr4_%d' % sid
    if not os.path.isdir(d):
        subprocess.run(FF + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', str(Z), '-selectid', str(sid),
                             '-export', 'sprite', d, W + 'gfx.swf'], check=True, stdout=subprocess.DEVNULL)
    sub = os.path.join(d, os.listdir(d)[0])
    G.add_leaf(sid, sub, origin, n)
RD = R.Renderer(G, 2)


def M(tx=0.0, ty=0.0, sx=1.0, sy=1.0, rot=0.0):
    r = math.radians(rot)
    return dict(a=math.cos(r) * sx, b=math.sin(r) * sx, c=-math.sin(r) * sy, d=math.cos(r) * sy, tx=tx, ty=ty)


def CX(m=1.0, add=(0, 0, 0), alpha=1.0):
    return dict(mult=[m, m, m, alpha], add=[add[0], add[1], add[2], 0])


def pct(prc, col):
    """Cs.setPercentColor"""
    c = prc / 100
    ra = int(100 - prc)
    return CX(int(ra * 2.56) / 256, (int(c * (col >> 16)), int(c * ((col >> 8) & 255)), int(c * (col & 255))))


cmds = []


def clip(sid, frame, mat, cx=R.NOCX, ctrl=None):
    i = R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))
    i.goto_and_stop(frame)
    RD.collect(i, mat, cx, set(), cmds)
    return i


# DP_BG: bg, its ha at frame 100 reddened (setPercentColor(ha, 30, 0xFF0000))
bgi = R.Instance(G, 76, ctrl={74: 100, '__noactions__': True})
eh = bgi.display[4]
ha = eh['inst'].display[1]
ha['cx'] = pct(30, 0xFF0000)
RD.collect(bgi, R.IDENT, R.NOCX, {'horloge'}, cmds)
# horloge (alpha 20 %): swfrender would give its alpha to the rotating mask of ha too (a Flash mask ignores the colour
# transform): drawn opaque in a layer, the alpha applied to the layer (its shapes do not overlap: the same as Flash)
hcmds = []
RD._emit(dict(eh, cx=dict(eh['cx'], mult=eh['cx']['mult'][:3] + [1.0])), eh['matrix'], R.NOCX, set(), hcmds)
cmds.append(('alpha', hcmds, eh['cx']['mult'][3]))
# DP_SCORE: scoreSquare (bg at 45 %, sf at (22.5, 22.5) 60 %), then partRound (frame 6, alpha 50)
sq = R.Instance(G, 31, ctrl={'__noactions__': True})
sq.display[1]['matrix'] = M(0.05, 0, 0.45, 0.45)
sq.display[3]['matrix'] = M(22.5, 22.5, 0.6, 0.6)
RD.collect(sq, M(255, 180), R.NOCX, set(), cmds)


def leaf(sid, age, mat, cx=R.NOCX):
    """a sprite drawn from its FFDec renders (frame age + 1)"""
    i = R.Instance(G, sid, ctrl={'__noactions__': True})
    i.age = age
    RD._emit(dict(inst=i, char=sid, matrix=R.IDENT, cx=R.NOCX), mat, cx, set(), cmds)


leaf(5, 5, M(285, 255), CX(alpha=0.5))
# DP_GROUND: the cubes in depth order (x * 100 + y)
cubes = [(s, 6 + 2 * n, n, s) for n in range(6) for s in range(1, 17)] + [(17, 6, 3, 5)]
for (x, y, n, s) in sorted(cubes, key=lambda c: c[0] * 100 + c[1]):
    cx = pct(50, 0xFFFFFF) if (x, y) == (17, 6) else R.NOCX
    clip(60, n + 1, M((x + 0.5) * 15, (y + 0.5) * 15), cx, {57: s, 39: 1})
# 4: butEndGame at its frame 11 (text alpha 50 %), smc over (shape 13)
be = R.Instance(G, 19, ctrl={'__noactions__': True})
be.goto_and_stop(11)
cmds.append(('shape', 13, M(150, 40), R.NOCX))
te = be.display[4]
leaf(18, 0, te['matrix'], te['cx'])
# DP_PARTS: partLight (150 %), partQueue (rotation 30, xscale 40, frame 1)
clip(33, 1, M(270, 105, 1.5, 1.5))
clip(22, 1, M(255, 120, 0.4, 1.0, 30))
# DP_HAND: mcScore at (300, 300), frame 11, its score panel at frame 2
clip(11, 11, M(300, 300), ctrl={10: 2})

canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
for c in cmds:
    if c[0] == 'alpha':
        layer = np.zeros_like(canvas)
        RD.draw(c[1], layer, (0, 0))
        layer *= c[2]
        canvas *= 1 - layer[..., 3:4]
        canvas += layer
    else:
        RD.draw([c], canvas, (0, 0))
im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').resize((600, 600), Image.LANCZOS)
out = Image.new('RGBA', (600, 600), (0, 0, 0, 255))
out.alpha_composite(im.convert('RGBA'))
os.makedirs(W + 'check', exist_ok=True)
out.convert('RGB').save(W + 'check/ref0.png')
print('ref0.png')
