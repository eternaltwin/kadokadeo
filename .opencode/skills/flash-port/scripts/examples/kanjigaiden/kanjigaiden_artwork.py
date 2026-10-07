"""Start screen of Kanji Gaiden (600 x 600), composed from SWF renders after the old thumbnail (snap/cover.jpg of the
archive, public/assets/img/games/Kanji_Gaiden.png): the view at pos 0.5, the three planes of bamboos drawn like
Plan.initBambooDraw / initNature (a fixed random), a monkey holding its banana on the front plane, a kunai thrown, the
foreground and Kanji's arm.
usage: kanjigaiden_artwork.py <out dir of kanjigaiden_assets.py (unused)> <artwork.jpg>"""
import os, sys, math, random
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kanjigaiden', '')
DST = sys.argv[2]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
G.inner_filters = True
G.blur_filters = True
rnd = random.Random(7)
POS = 0.5


def M(a=1, b=0, c=0, d=1, tx=0, ty=0):
    return dict(a=a, b=b, c=c, d=d, tx=tx, ty=ty)


def mul(m, n):
    return R.mat_mul(m, n)


def percent_color(prc, col):
    c = prc / 100.0
    m = (100 - int(prc)) / 100.0
    return dict(mult=[m, m, m, 1.0], add=[int(c * ((col >> 16) & 0xFF)), int(c * ((col >> 8) & 0xFF)), int(c * (col & 0xFF)), 0])


cmds = []


def put(sid, m, ctrl=None, cx=R.NOCX, patch=None):
    c = dict(ctrl or {})
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    if patch:
        patch(inst)
    R.Renderer(G, 2).collect(inst, m, cx, set(), cmds)


def plan_x(cz):
    width = math.ceil(300 + 600 * (1 - cz))
    return -math.floor(POS * (width - 300)), width


def bamboo(P, x, y, xs, rot, cz, cx, mask_y=None):
    a = 3.14 * rot / 180
    sx, sy = xs / 100.0, abs(xs) / 100.0
    m = mul(P, M(math.cos(a) * sx, math.sin(a) * sx, -math.sin(a) * sy, math.cos(a) * sy, x, y))

    def patch(inst):
        if mask_y is not None:
            for e in inst.display.values():
                if e['name'] == 'mask':
                    e['matrix'] = dict(e['matrix'], ty=mask_y)
    put(126, m, {125: rnd.randrange(5) + 1, 113: rnd.randrange(4) + 1}, cx, patch)


def plane(nb_pl, cz, prc):
    """Plan.initBambooDraw + initNature, in screen coordinates"""
    cx = percent_color(prc, 0xD4FBA2) if prc else R.NOCX
    px, width = plan_x(cz)
    P = M(tx=px)
    z = 150 + math.floor(150 * cz)
    bamboo(P, 0, z, cz * 100, -6, cz, cx)
    bamboo(P, width, z - 15 * math.sin(3.14), cz * 100, 6, cz, cx)
    nb = math.ceil(width / 120) + nb_pl * 7
    rng_ = math.ceil(width / nb)
    for i in range(nb):
        x = rng_ * i + rnd.randrange(rng_ - 30) - (rng_ - 30) / 2
        r = math.sin(x / width * 3.14)
        y = z - 15 * r
        rot = -(6 - r * 6) if x < width * 0.5 else 6 - r * 6
        xs = cz * 100 if rnd.randrange(2) == 1 else -cz * 100
        bamboo(P, x, y, xs, rot, cz, cx, rnd.randrange(385))
    for i in range(math.ceil(width / (100 * cz))):
        hx = i * 300 * cz
        hy = z - 15 * math.sin(hx / width * 3.14) + cz * 20
        put(35, mul(P, M(cz, 0, 0, cz, hx, hy)), None, cx)
    return P, z, cx


def monkey(P, z, cz, x, cx, diff, frame, banana, flip=False):
    y = z - (15 + 5 * (1 - cz)) * math.sin(x / math.ceil(300 + 600 * (1 - cz)) * 3.14)
    s = -cz if flip else cz
    put(108, mul(P, M(s, 0, 0, cz, x, y)), {108: diff, {1: 81, 2: 94, 3: 107}[diff]: frame, 58: banana}, cx)


# Game.initPlan: background, planes 2, 1, 0 (each: its monkeys under its bitmap), shots, foreground, hero
put(128, M(tx=plan_x(0)[0]))
P2, z2, c2 = plane(2, 0.125, 50)
P1, z1, c1 = plane(1, 0.25, 25)
monkey(P1, z1, 0.25, 470, c1, 2, 50, 2)
P0px, w0 = plan_x(0.5)
P0 = M(tx=P0px)
z0 = 150 + math.floor(150 * 0.5)
monkey(P0, z0, 0.5, 345, R.NOCX, 1, 8, 1)
plane(0, 0.5, 0)
put(16, M(1.0, 0, 0, 1.0, 104, 152), {16: 1, 14: 1})
put(38, M(tx=plan_x(0.75)[0]))
put(33, M(tx=150, ty=300), {32: 20, 27: 1, 21: 1})

Z = G.Z
cv = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
R.Renderer(G, 2).draw(cmds, cv, (0, 0))
im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
im = im.resize((600, 600), Image.LANCZOS)
bg = Image.new('RGBA', (600, 600), (255, 255, 255, 255))
bg.alpha_composite(im)
bg.convert('RGB').save(DST, quality=92)
print('artwork', DST)
