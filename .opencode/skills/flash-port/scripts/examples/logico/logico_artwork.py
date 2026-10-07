"""Start screen of Logico (public/assets/img/gfx/artwork/logico.jpg, 600 x 600), composed from SWF renders after the
layout of the old thumbnail (artwork/old/logico.gif): a close-up of the top left of the board, balls along the
golden ring, one under the mouse (Game.ballOver glows), a line of 4 in the flash of a combo (Game.updateCombo), a
ball flying across with its plasma trail (blurred, added) and the light bubbles of a burst (partLight). The "LOGIC'"
title of the thumbnail is not in the SWF: no title.
usage: logico_artwork.py <out.jpg>   (after prepare_game.sh: $KKP_WORK/logico holds game.swf and its exports)
"""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'logico', '')
G = R.SWF(W + 'game.swf', W + 'shp4_game', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, Z)

# blendMode "subtract" inside the ball (see logico_assets.py)
_blend_into = R.blend_into


def blend_into(canvas, layer, blend):
    if blend != 'subtract':
        return _blend_into(canvas, layer, blend)
    la, ca = layer[..., 3:4], canvas[..., 3:4]
    cs = np.where(la > 0, layer[..., :3] / np.maximum(la, 1e-6), 0)
    cb = np.where(ca > 0, canvas[..., :3] / np.maximum(ca, 1e-6), 0)
    rgb = layer[..., :3] * (1 - ca) + canvas[..., :3] * (1 - la) + la * ca * np.maximum(cb - cs, 0)
    canvas[..., 3:4] = ca + la * (1 - ca)
    canvas[..., :3] = rgb


R.blend_into = blend_into

# the part of the stage shown: 150 x 150 Flash pixels from (X0, Y0), drawn at 4 px per Flash pixel
X0, Y0, SPAN = 8.0, 18.0, 150.0
O = (X0, Y0)
N = int(SPAN * Z)


def inst(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def cmds(i, M=R.IDENT, cx=R.NOCX):
    out = []
    RD.collect(i, M, cx, set(), out)
    return out


def at(x, y, s=1.0):
    return dict(a=s, b=0.0, c=0.0, d=s, tx=x, ty=y)


def layer(cm):
    c = np.zeros((N, N, 4), dtype=np.float32)
    RD.draw(cm, c, O)
    return c


def over(canvas, top):
    canvas *= (1 - top[..., 3:4])
    canvas += top


def blur(a, b):
    return R.box_blur(a, b * Z, b * Z, 1)


def outer_glow(c, b, s):
    g = np.clip(blur(c[..., 3], b) * s, 0, 1)
    out = c.copy()
    a = c[..., 3]
    for k in range(3):
        out[..., k] += g * (1 - a)
    out[..., 3] += g * (1 - a)
    return out


def inner_glow(c, b, s):
    a = c[..., 3]
    g = np.clip(blur(1 - a, b) * s, 0, 1) * a
    out = c * (1 - g[..., None])
    for k in range(3):
        out[..., k] += g
    return out


BALL = G.sid('mcBall')
canvas = layer(cmds(inst(G.sid('mcBg'))))
shade = np.zeros_like(canvas)
balls = np.zeros_like(canvas)

# balls along the ring (centre 150, 150), from the left to the top: (angle, colour, look)
RAY = 112
ring = [(167, 1, ''), (180, 0, ''), (193, 2, 'combo'), (206, 2, 'combo'), (219, 2, 'combo'), (232, 2, 'combo'),
        (245, 3, 'over'), (258, 0, ''), (271, 1, ''), (284, 2, '')]
for deg, col, look in ring:
    a = math.radians(deg)
    x, y = 150 + math.cos(a) * RAY, 150 + math.sin(a) * RAY
    over(shade, layer(cmds(inst(G.sid('mcBallShadow')), at(x - 5, y + 4))))
    if look == 'combo':
        # Game.updateCombo at tcoef = 0.48: setPercentColor(48, white), glow(c * 30, c), c = tcoef^2
        t = 0.48
        cx = dict(mult=[int(100 - t * 100) / 100.0] * 3 + [1.0], add=[int(t * 255)] * 3 + [0])
        b = outer_glow(layer(cmds(inst(BALL, {'smc': col + 1}), at(x, y), cx)), t * t * 30, t * t)
    else:
        b = layer(cmds(inst(BALL, {'smc': col + 1}), at(x, y)))
        if look == 'over':
            b = outer_glow(inner_glow(b, 8, 2), 2, 4)
    over(balls, b)
# the shadows: blendMode "layer" at 50 %
over(canvas, shade * 0.5)
over(canvas, balls)

# a ball sent across the ring, with its plasma trail: the ball drawn along its path, blurred, added
tx, ty, fx, fy = 122.0, 118.0, 150.0, 150.0
trail = np.zeros_like(canvas)
for k in range(10):
    u = k / 9.0
    over(trail, layer(cmds(inst(BALL, {'smc': 4}), at(fx + (tx - fx) * u, fy + (ty - fy) * u))) * (0.25 + 0.75 * u))
for k in range(4):
    trail = np.stack([blur(trail[..., i], 8) for i in range(4)], axis=-1)
canvas[..., :3] = np.minimum(canvas[..., :3] + trail[..., :3], 1)
hot = layer(cmds(inst(BALL, {'smc': 4}), at(tx, ty)))
over(canvas, hot)
canvas[..., :3] = np.minimum(canvas[..., :3] + hot[..., :3] * 0.6, 1)

# light bubbles (partLight) around the combo
LIGHT = G.sid('partLight')
lsid = inst(LIGHT).display[1]['inst'].sid
rs = 7
for k in range(14):
    rs = (rs * 1103515245 + 12345) & 0x7fffffff
    a = math.radians(188 + (rs >> 8) % 50)
    rr = RAY + ((rs >> 4) % 36) - 18
    s = 0.6 + ((rs >> 12) % 10) / 10.0
    over(canvas, layer(cmds(inst(lsid, {lsid: 1 + k % 2}), at(150 + math.cos(a) * rr, 150 + math.sin(a) * rr, s))))

im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGB')
im.save(sys.argv[1], quality=92)
print(sys.argv[1], im.size)
