"""Start screen of Quadrikolor (public/assets/img/gfx/artwork/quadrikolor.jpg, 600 x 600) composed from SWF renders (the
title of the old thumbnail artwork/old/quadrikolor.gif is not in the SWF): a moment of a game as the code places it:
the table (bg), the four holes (trou at 70 %, flipped, their jets on various frames), the seven balls in their colours
(Ball.initColor), the ship aiming at the red ball for the top right hole with its aiming line (Game.drawLines: strokes
26 px wide at 20 / 16 / 12 % white, a lineseg mark at each bounce) and the bar (carburant, x 7).
usage: quadrikolor_artwork.py <out jpg>"""
import os, sys, math, glob, subprocess, io, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'quadrikolor', '')
DST = sys.argv[1]
K = 2
COLORS = [0xDD0000, 0xEEAA00, 0xDDEE22, 0x33DD22, 0x22AA88, 0x4488EE, 0xAA55DD]
RAW = open(W + 'gfx.swf', 'rb').read()
DATA = RAW[:8] + (zlib.decompress(RAW[8:]) if RAW[:3] == b'CWS' else RAW[8:])
_b = SD.Bits(DATA, 8); _b.rect(); _b.u16(); _b.u16()
TAGS = SD.read_tags(DATA, _b.pos, len(DATA))


def new_swf(color=None):
    """(quadrikolor_assets.new_swf: the static texts as shapes, the colour of a ball)"""
    G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
    G.flash_replace = True
    for code, body in TAGS:
        if code in (11, 33):
            tid = struct.unpack_from('<H', body, 0)[0]
            r = subprocess.run(['rsvg-convert', '-z', str(G.Z)], input=open(W + 'txt_gfx/%d.svg' % tid, 'rb').read(),
                               capture_output=True, check=True)
            G.shapes[tid] = list(SD.Bits(body, 2).rect())
            G._shape_cache[tid] = Image.open(io.BytesIO(r.stdout)).convert('RGBA')
    if color is not None:
        t = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[(color >> 16) - 255, ((color >> 8) & 0xFF) - 255, (color & 0xFF) - 255, 0])
        for sid, char in ((132, 101), (132, 124), (106, 104)):
            for ops in G.sprites[sid].frames:
                for kind, v in ops:
                    if kind == 'place' and v.get('char') == char:
                        v['cx'] = t
    return G


G = new_swf()
Z = G.Z
canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)


def over(layer):
    np.multiply(canvas, 1 - layer[..., 3:4], out=canvas)
    np.add(canvas, layer, out=canvas)


def draw(G, name, ctrl, x, y, sx=1.0, sy=1.0, rot=0.0, alpha=1.0):
    sid = G.sid(name)
    c = dict(ctrl)
    c.setdefault(sid, 1)
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    a, s = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    out = []
    rd = R.Renderer(G, K)
    cx = dict(mult=[1.0, 1.0, 1.0, alpha], add=[0, 0, 0, 0])
    rd.collect(inst, dict(R.IDENT, a=a * sx, b=s * sx, c=-s * sy, d=a * sy, tx=x, ty=y), cx, set(), out)
    layer = np.zeros_like(canvas)
    rd.draw(out, layer, (0, 0))
    over(layer)


def stroke(x0, y0, x1, y1, r, alpha):
    """lineStyle(2 r, white, alpha) + lineTo: a stroke with round caps (anti-aliased at the zoom of the canvas)"""
    yy, xx = np.mgrid[0:300 * Z, 0:300 * Z].astype(np.float32) / Z
    dx, dy = x1 - x0, y1 - y0
    L2 = dx * dx + dy * dy
    t = np.clip(((xx - x0) * dx + (yy - y0) * dy) / L2, 0, 1)
    d = np.hypot(xx - (x0 + t * dx), yy - (y0 + t * dy))
    cov = np.clip((r - d) * Z + 0.5, 0, 1) * alpha
    layer = np.zeros_like(canvas)
    layer[..., :3] = cov[..., None]
    layer[..., 3] = cov
    over(layer)


draw(G, 'bg', {}, 0, 0)
# Game.initLevel: the holes, their 7 jets each on another frame
for i, (x, y, sx, sy) in enumerate(((0, 14, 0.7, 0.7), (300, 14, -0.7, 0.7), (0, 300, 0.7, -0.7), (300, 300, -0.7, -0.7))):
    draw(G, 'trou', {165: 8 + 9 * i}, x, y, sx, sy)
BALLS = {0: (196, 104), 1: (72, 88), 2: (226, 236), 3: (58, 196), 4: (118, 254), 5: (146, 58), 6: (262, 168)}
for i, (x, y) in BALLS.items():
    draw(new_swf(COLORS[i]), 'ball', {}, x, y)
# the ship aims at the red ball for the top right hole (ghost ball: the contact point away from the hole)
ship = (104, 186)
bx, by = 300 - BALLS[0][0], 14 - BALLS[0][1]
bd = math.hypot(bx, by)
gx, gy = BALLS[0][0] - bx / bd * 26, BALLS[0][1] - by / bd * 26
rot = math.degrees(math.atan2(gy - ship[1], gx - ship[0]))
# Game.drawLines (carbu 7: 570 px), the bounds of the table
totd, a, px, py, alpha = 500 + 10 * (14 - 7), math.radians(rot), ship[0], ship[1], 20
marks = []
while totd > 0:
    sx, sy = math.cos(a), math.sin(a)
    m, nx, ny = float('inf'), 0, 0
    for d, x, y in (((px - 0 - 13) / -sx if sx else float('inf'), 1, 0), ((py - 14 - 13) / -sy if sy else float('inf'), 0, 1),
                    ((px - 300 + 13) / -sx if sx else float('inf'), -1, 0), ((py - 300 + 13) / -sy if sy else float('inf'), 0, -1)):
        if 0.1 < d < m:
            m, nx, ny = d, x, y
    d = min(m, totd)
    totd -= d
    if alpha > 0:
        stroke(px, py, px + d * sx, py + d * sy, 13, alpha / 100)
    px, py = px + d * sx, py + d * sy
    if totd > 0:
        marks.append((px, py, alpha * 100 / 20))
    k = 1.8 * (nx * sx + ny * sy)
    sx, sy = sx - k * nx, sy - k * ny
    a = math.atan2(sy, sx)
    alpha -= 4
for x, y, al in marks:
    if al > 0:
        draw(G, 'lineseg', {}, x, y, alpha=min(1, al / 100))
draw(G, 'ship', {'reacteur': 1}, ship[0], ship[1], rot=rot)
# the bar: carburant, 14 full squares, the multiplier x7 (the picture of the game's text field)
draw(G, 'bar', {}, 0, 0)
for i in range(14):
    draw(G, 'square', {'s': 1}, 79 + i * 10, 3)
img = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
img = img.resize((600, 600), Image.LANCZOS)
txt = os.path.join(W, 'out', 'src', 'txtMulti', '8.png')
pv = None
import json
pv = json.load(open(os.path.join(W, 'out', 'pivots.json')))['txtMulti']
t = Image.open(txt).convert('RGBA')
img.alpha_composite(t, (int(round(-pv[0] * t.width)), int(round(-pv[1] * t.height))))
img.convert('RGB').save(DST, quality=90)
print(DST)
