"""Start screen of Judo Commando (public/assets/img/gfx/artwork/judocommando.jpg, 600 x 600), composed from SWF renders
after the vignette of the original (vig.gif): the inside of the tower seen like in the game (150 x 150 Flash pixels,
the map zoomed x2, drawn x2), soldiers and a ninja on a plank, the hero throwing a soldier, the gorilla on the floor.
Rendered at 1 px per Flash pixel with nearest sampling, then enlarged x4 without smoothing (Flash's "low" quality).
usage: judocommando_artwork.py <out.jpg>      (after prepare_game.sh, see rebuild_assets.sh)"""
import os, sys, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'judocommando', '')
G = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)
G.flash_replace = True
G.nearest = True
rd = R.Renderer(G, 1)
rng = random.Random(7)
U = 150
cv = np.zeros((U, U, 4), dtype=np.float32)
DARK = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[-30, -30, -30, 0])


def M(x, y, sx=1.0):
    return dict(a=sx, b=0.0, c=0.0, d=1.0, tx=x, ty=y)


def put(sid, ctrl, x, y, sx=1.0, cx=R.NOCX, hide=()):
    inst = R.Instance(G, sid, ctrl=dict(ctrl, __noactions__=True))
    cmds = []
    rd.collect(inst, M(x, y, sx), cx, set(hide), cmds)
    rd.draw(cmds, cv, (0, 0))


# the wall at the back: mcTiles (its smc on a random frame every 10 px)
for x in range(0, U, 10):
    for y in range(0, U, 10):
        put(34, {33: rng.randrange(G.sprites[33].nframes) + 1}, x, y)
# the level: the planks of row 5, the bricks of the floor (rows 8, 9) and of the wall on the right (darker: -30)
for gx in range(0, 8):
    put(1122, {1122: 3, 1121: rng.randrange(34) + 1}, gx * 16 - 1, 5 * 16 - 1, cx=DARK, hide=('ladder',))
for gx in range(0, 10):
    for gy in (8, 9):
        put(1122, {1122: 2, 1107: rng.randrange(53) + 1}, gx * 16 - 1, gy * 16 - 1, cx=DARK, hide=('ladder',))
for gy in range(0, 8):
    put(1122, {1122: 2, 1107: rng.randrange(53) + 1}, 8 * 16 - 1, gy * 16 - 1, cx=DARK, hide=('ladder',))

MON = 1077
PARTS = {'Standard': {446: 4, 439: 2, 449: 2}, 'Soldat': {446: 1, 439: 2, 449: 1}, 'Heavy': {446: 1, 439: 3, 449: 2}}


def soldier(kind, label, sub, f, x, y, sx):
    lab = G.sprites[712].labels[label]
    put(MON, {MON: 1, 712: lab, sub: f, **PARTS[kind]}, x, y, sx)


# on the plank: a soldier walking, another aiming
soldier('Standard', 'walk', 639, 9, 22, 71, 1)
soldier('Soldat', 'aim', 674, 1, 46, 71, 1)
# the ninja jumping in
put(MON, {MON: 5, 834: G.sprites[834].labels['jumpRoll'], 792: 3}, 92, 52, -1)
# on the floor: the hero grappling a ninja (Hero.grapple: 0.4 square apart, face to face), the gorilla coming
put(611, {611: G.sprites[611].labels['grapple']}, 54, 119, 1)
put(MON, {MON: 5, 834: G.sprites[834].labels['grappling']}, 60.4, 119, -1)
put(MON, {MON: 6, 976: G.sprites[976].labels['walk'], 868: 12}, 104, 119, -1)

im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGB')
im = im.resize((600, 600), Image.NEAREST)
im.save(sys.argv[1], quality=92)
print('artwork', sys.argv[1])
