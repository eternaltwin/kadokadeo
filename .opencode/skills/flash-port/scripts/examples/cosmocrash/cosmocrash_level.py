"""Cosmo Crash level: Game.genLevel of the original, replayed in Python to draw the ground bitmap (bmpLevel) from the
SWF shapes.

The level is the same in every game: genLevel draws from `new mt.Rand(0)` (topography, the 3 platforms, the rocks), so
the 2000 x 450 bitmap the original drew at run time (BitmapData.draw of mcRocher and mcDirt, fillRect) is drawn here
once, at 2 px per Flash pixel. The game computes the topography and the platforms itself (same calls of the same
generator): level() returns them so the asset script can check them against the game (Data.LEVEL_CHECK).
"""
import math
import numpy as np
from PIL import Image
import swfrender as R

LW, LH = 2000, 450
PW = 40
PMAX = LW // PW
EC = 8


class Rand:
    """mt.Rand (Parker-Miller-Carta LCG, Flash 8 / JS variant: exact in doubles)"""

    def __init__(self, seed):
        self.seed = (-seed if seed < 0 else seed) + 131

    def int(self):
        self.seed = (self.seed * 16807) % 0x7FFFFFFF
        return self.seed & 0x3FFFFFFF

    def random(self, n):
        return self.int() % n

    def rand(self):
        return (self.int() % 10007) / 10007.0


def smod(n, mod):
    while n >= mod:
        n -= mod
    while n < 0:
        n += mod
    return n


def level():
    """genLevel without the drawing: (top, plats [(x, y, ray, rampeX)], draw ops)"""
    seed = Rand(0)
    # genTop
    top = [3] * PMAX
    ray = 2
    for i in range(PMAX):
        index = seed.random(PMAX)
        for dx in range(ray * 2 + 1):
            ind = int(smod(index + dx - ray, PMAX))
            top[ind] += 1 + ray - int(abs(dx - ray))
    hmax, lim = 25, 5
    prev = top[PMAX - 1]
    for i in range(PMAX):
        if top[i] > hmax:
            top[i] = hmax
        dif = top[i] - prev
        if dif > lim:
            top[i] += lim - dif
        if dif < -lim:
            top[i] += -lim - dif
        prev = top[i]

    def ground(x):
        px = int(x / PW)
        c = x / PW - px
        sy, ey = top[px], top[(px + 1) % PMAX]
        return LH - int((sy * (1 - c) + ey * c) * EC)

    # plats
    plats = []
    to = 0
    m = 150
    for i in range(3):
        while True:
            x = m + seed.random(LW - 2 * m)
            if all(abs(p[0] - x) >= 300 for p in plats):
                px = int(x / PW)
                ly = max(top[px], top[(px + 1) % PMAX])
                y = LH - int(ly * EC + 50 + seed.rand() * 50)
                pray = 25 + i * 25
                rampe_x = 8 + seed.random(int(pray * 2 - 38)) - pray      # Plat.new: skin.rampe._x
                plats.append((x, y, pray, rampe_x))
                break
            to += 1
            if to > 100:
                raise Exception('GEN PLATS')

    ops = []
    # rocks (rotation of seed.random(8) * 45 radians: Matrix.rotate takes radians)
    for i in range(PMAX):
        for ni in range(seed.random(3)):
            x = seed.random(PW) + i * PW
            y = ground(x)
            rot = seed.random(8) * 45
            fr = seed.random(5) + 1
            ops.append(('rock', fr, rot, int(x), int(y), None))
    # dirt
    for i in range(PMAX):
        ly, nxt = top[i], top[(i + 1) % PMAX]
        my = min(ly, nxt)
        ops.append(('fill', i * PW, LH - my * EC, PW, my * EC))
        ops.append(('dirt', nxt - ly + 6, i * PW, LH - ly * EC))
    # rocks half buried: clipped to the part above their centre (getBounds of the unrotated frame)
    for i in range(PMAX):
        for ni in range(seed.random(4)):
            x = seed.random(PW) + i * PW
            y = ground(x) + 3 + seed.random(2)
            rot = seed.random(8) * 45
            fr = seed.random(5) + 1
            ops.append(('rock', fr, rot, x, y, 'clip'))
    return top, plats, ops


def render(G, ops, k=2):
    """bmpLevel at k px per Flash pixel (RGBA, LW*k x LH*k): the ops of level() in order, like BitmapData.draw"""
    Z = G.Z
    rocher, dirt = G.sid('mcRocher'), G.sid('mcDirt')
    rd = R.Renderer(G, k)
    full = np.zeros((LH * Z, LW * Z, 4), dtype=np.float32)
    for op in ops:
        if op[0] == 'fill':
            _, x, y, w, h = op
            full[y * Z:(y + h) * Z, x * Z:(x + w) * Z] = [0, 0, 0, 1]
            continue
        if op[0] == 'rock':
            _, fr, rot, x, y, clip = op
            inst = R.Instance(G, rocher, ctrl={'__noactions__': True})
            inst.goto_and_stop(fr)
            ca, sa = math.cos(rot), math.sin(rot)
            M = dict(a=ca, b=sa, c=-sa, d=ca, tx=float(x), ty=float(y))
        else:
            _, fr, x, y = op
            inst = R.Instance(G, dirt, ctrl={'__noactions__': True})
            inst.goto_and_stop(max(1, min(G.sprites[dirt].nframes, fr)))
            M = dict(a=1.0, b=0.0, c=0.0, d=1.0, tx=float(x), ty=float(y))
            clip = None
        cmds = []
        rd.collect(inst, M, R.NOCX, set(), cmds)
        bb = rd.bounds(cmds)
        if bb is None:
            continue
        # draw on a window of the level around the brush (Flash clips to the bitmap)
        x0 = max(0, int(math.floor(bb[0])) - 2)
        y0 = max(0, int(math.floor(bb[1])) - 2)
        x1 = min(LW, int(math.ceil(bb[2])) + 2)
        y1 = min(LH, int(math.ceil(bb[3])) + 2)
        if x1 <= x0 or y1 <= y0:
            continue
        lay = np.zeros(((y1 - y0) * Z, (x1 - x0) * Z, 4), dtype=np.float32)
        rd.draw(cmds, lay, (x0, y0))
        if clip:
            # draw(brush, m, null, null, rect): rect from the bounds of the brush's current frame (not rotated)
            b = rd.bounds([c for c in cmds_unrotated(rd, inst)])
            rx, ry = int(x + b[0]), int(y + b[1])
            rw, rh = int(math.ceil(b[2] - b[0])), int(math.ceil(-b[1])) + 1
            mask = np.zeros(lay.shape[:2], dtype=np.float32)
            mx0, my0 = max(0, (rx - x0) * Z), max(0, (ry - y0) * Z)
            mx1, my1 = max(0, (rx + rw - x0) * Z), max(0, (ry + rh - y0) * Z)
            mask[my0:my1, mx0:mx1] = 1
            lay *= mask[..., None]
        sub = full[y0 * Z:y1 * Z, x0 * Z:x1 * Z]
        sub *= (1 - lay[..., 3:4])
        sub += lay
    im = Image.fromarray(np.clip(full * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    return im.resize((LW * k, LH * k), Image.LANCZOS).convert('RGBA')


def cmds_unrotated(rd, inst):
    out = []
    rd.collect(inst, R.IDENT, R.NOCX, set(), out)
    return out
