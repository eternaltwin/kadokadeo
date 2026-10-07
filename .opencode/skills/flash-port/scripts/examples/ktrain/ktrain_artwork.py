"""Start screen of K-Train (public/assets/img/gfx/artwork/ktrain.jpg, 600 x 600) composed from SWF renders, after the
layout of the old thumbnail (gfx/ktrain.gif of the archive): a close-up of the desert, the locomotive on its rails on
the right with its shadow, the driver walking back to it from a pile of gems, his footprints, a cactus and a stain of
sand. Composed at 1 px per Flash pixel (the bitmaps at their native resolution, the shadows multiplied like in the
game) on a window of 200 x 200 Flash pixels, then enlarged x3 without smoothing.
usage: ktrain_artwork.py <out dir of ktrain_assets.py> <out jpg>"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'ktrain', '')
OUT, DST = sys.argv[1], sys.argv[2]
G = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)
G.flash_replace = True
G.nearest = True
# the hit zones (blend mode "alpha"): not drawn by Flash
for sd in G.sprites.values():
    for i, ops in enumerate(sd.frames):
        sd.frames[i] = [(k, v) for k, v in ops if not (k == 'place' and v.get('blend') == 'alpha')]
SIZE = 200
canvas = np.zeros((SIZE, SIZE, 4), dtype=np.float32)


def mat(x, y, sx=1.0, sy=None):
    return dict(a=sx, b=0.0, c=0.0, d=sx if sy is None else sy, tx=x, ty=y)


def draw(name, frame, x, y, blend=None, sy=1.0, alpha=1.0):
    sid = G.sid(name)
    inst = R.Instance(G, sid, ctrl={sid: frame, '__noactions__': True})
    cmds = []
    R.Renderer(G, 1).collect(inst, mat(x, y, 1.0, sy), R.NOCX, set(), cmds)
    lay = np.zeros_like(canvas)
    R.Renderer(G, 1).draw(cmds, lay, (0, 0))
    lay *= alpha
    if blend == 'multiply':
        R.blend_into(canvas, lay, 'multiply')
    else:
        canvas[...] = canvas * (1 - lay[..., 3:4]) + lay


# the ground (mcBg frame 1: the desert bitmap, its track at x 150), window from y 50 of the bitmap
draw('mcBg_terre', 1, 150, 100)
# a stain of sand and the footprints from the gems to the driver, drawn into the ground
draw('mcObjets_terre', 9, 28, 168)
draw('mcObjets_terre', 11, 182, 36)
for i, y in enumerate(range(92, 140, 6)):
    draw('mcFoot', 1, 98 + (3 if i % 2 == 0 else -3) + (y - 92) * 0.12, y)
# the rails
for y in (-70, 50, 170):
    draw('mcRail', 1, 150, y)
# the cactus and its shadow (the obstacles: shadow plane under them)
draw('mcObjets_terre_ombre', 1, 70, 214, blend='multiply')
draw('mcObjets_terre', 1, 70, 214)
# the gems
draw('mcTresors', 2, 58, 70)
# the driver walking down to the train and his shadow
draw('ombre_pilote', 1, 108, 146, blend='multiply')
draw('mcPilote', 2, 108, 146)
# the locomotive and its shadow
draw('mc_ombre_train', 1, 150, 242, blend='multiply')
draw('mcLoco', 1, 150, 242)

im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGB')
im = im.resize((600, 600), Image.NEAREST)
im.save(DST, quality=92)
print('artwork', DST)
