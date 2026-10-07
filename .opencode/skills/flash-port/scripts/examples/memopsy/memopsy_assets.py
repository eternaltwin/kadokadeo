"""Builds the Memopsy graphics for KadoKadeo from the original SWF.

The released memo.swf holds gfx.swf with obfuscated export names (same ids, same timelines, same shapes: checked by
comparing the dumps), so the pictures are rendered from gfx.swf, whose names are readable.

Memopsy has no character animation: every symbol is rendered at x2 ("simple renders" pipeline) and the code
(Game.hx, Gfx.hx, MC.hx) plays the few timelines from tables:
  - card (25, 11 frames): frame 1 the back, frames 2-11 the face with one of the 10 symbols: one picture per frame;
    its shape is also the hit area of the onPress button (a run-length mask: the corners are rounded);
  - flip (26, 9 frames): two nested card clips ("back" at depth 1, "top" at depth 4) moved and squeezed by the
    timeline: no picture of its own, the per-frame matrices and colour transforms (a grey multiplier -> tint, an
    alpha of 0 or 1 -> visibility) go to Data.hx and the game replays them on two card clips;
  - good (32, 6 frames): the white flash over a found pair (frames 1-5; frame 6 is stop() + removeMovieClip());
  - life (36, 2 frames): a bead of the life bar (gold / spent);
  - bgAnim (38): the big excentric circles turned by the code (its origin is the rotation centre);
  - bg (40): the brown 300 x 320 background.
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: memopsy_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/memopsy holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'memopsy', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, K)

pivots = {}
area = {}
meta = {}


def save_anim(name, imgs, reg):
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    w, h = imgs[0].size
    for i, im in enumerate(imgs):
        assert im.size == (w, h), name
        im.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(reg[0] / w, 6), round(reg[1] / h, 6)]
    a = 0
    for im in imgs:
        bb = im.split()[3].getbbox()
        if bb:
            a += (bb[2] - bb[0]) * (bb[3] - bb[1])
    area[name] = a


class Box:
    """a rectangle of world units drawn at Z pixels per unit, reduced to `res` pixels per unit; its origin is on the
    pixel grid of the reduced picture"""

    def __init__(self, x0, y0, x1, y1, res=K, pad=1.0):
        step = 1.0 / res
        self.res = res
        self.ox = math.floor((x0 - pad) / step) * step
        self.oy = math.floor((y0 - pad) / step) * step
        ex = math.ceil((x1 + pad) / step) * step
        ey = math.ceil((y1 + pad) / step) * step
        self.w = int(round((ex - self.ox) * res))
        self.h = int(round((ey - self.oy) * res))
        self.Wz = int(round(self.w / res * Z))
        self.Hz = int(round(self.h / res * Z))

    def canvas(self):
        return np.zeros((self.Hz, self.Wz, 4), dtype=np.float32)

    def draw(self, cmds, canvas=None):
        c = self.canvas() if canvas is None else canvas
        RD.draw(cmds, c, (self.ox, self.oy))
        return c

    def reg(self):
        return (-self.ox * self.res, -self.oy * self.res)

    def image(self, canvas):
        """premultiplied canvas at Z -> straight RGBA picture at res"""
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        return im.resize((self.w, self.h), Image.LANCZOS).convert('RGBA')


def inst(sid, ctrl=None):
    return R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))


def frame_cmds(i):
    out = []
    RD.collect(i, R.IDENT, R.NOCX, set(), out)
    return out


def anim_frames(sid, frames, pad=1.0):
    """every frame of a sprite in one shared box"""
    i = inst(sid)
    cms = []
    for f in frames:
        i.goto_and_stop(f)
        cms.append(frame_cmds(i))
    bb = [RD.bounds(c) for c in cms if c]
    b = Box(min(x[0] for x in bb), min(x[1] for x in bb), max(x[2] for x in bb), max(x[3] for x in bb), pad=pad)
    return [b.image(b.draw(c)) for c in cms], b.reg()


# ---------------------------------------------------------------- card (25): 11 frames, one picture each
sp = G.sprites[25]
assert sp.nframes == 11 and sp.actions == {}
imgs, reg = anim_frames(25, range(1, 12))
save_anim('card', imgs, reg)
meta['cardFrames'] = sp.nframes

# hit area of a card (its onPress button): shape 2 (the back: the only shape of frame 1, the face has the same
# outline), a run-length mask at 4 samples per Flash pixel (its alpha >= 0.5), like Toy Maniak's slots
ci = inst(25)
assert ci.display[1]['char'] == 2 and ci.display[1]['matrix'] == R.IDENT
HS = 4
x0, x1, y0, y1 = G.shapes[2]
s2 = np.asarray(G.shape_image(2), dtype=np.float32)[..., 3] / 255.0
assert s2.shape == (int(round((y1 - y0) * Z)), int(round((x1 - x0) * Z))) and Z == HS
rows = []
for y in range(s2.shape[0]):
    r = s2[y] >= 0.5
    runs = []
    xx = 0
    while xx < len(r):
        if r[xx]:
            s = xx
            while xx < len(r) and r[xx]:
                xx += 1
            runs += [s, xx]
        else:
            xx += 1
    rows.append(runs)
meta['cardHit'] = dict(x0=x0, y0=y0, res=HS, rows=rows)

# ---------------------------------------------------------------- flip (26): the timelines of back (d=1) and top (d=4)
sp = G.sprites[26]
assert sp.nframes == 9 and sp.actions == {}
fi = inst(26)
flip = {}
for d, name in ((1, 'back'), (4, 'top')):
    rows = []
    for f in range(1, sp.nframes + 1):
        fi.goto_and_stop(f)
        e = fi.display[d]
        m, cx = e['matrix'], e['cx']
        assert e['char'] == 25 and m['b'] == 0 and m['c'] == 0 and m['d'] == 1 and cx['add'] == [0, 0, 0, 0]
        mu = cx['mult']
        assert mu[0] == mu[1] == mu[2] and mu[3] in (0.0, 1.0)
        # x, y, xscale, grey multiplier (tint), shown (the alpha multiplier is 0 or 1)
        rows.append([m['tx'], m['ty'], m['a'], mu[0], mu[3]])
    flip[name] = rows
assert fi.display[1]['name'] == 'back' and fi.display[4]['name'] == 'top'
meta['flip'] = flip
meta['flipFrames'] = sp.nframes

# ---------------------------------------------------------------- good (32): frames 1-5; 6 is stop + removeMovieClip
sp = G.sprites[32]
assert sp.nframes == 6 and list(sp.actions.keys()) == [6] and sp.actions[6][0] == ('stop',)
imgs, reg = anim_frames(32, range(1, 6))
# frame 6 never shows (its script removes the clip before the display): an empty picture keeps the table square
imgs.append(Image.new('RGBA', imgs[0].size, (0, 0, 0, 0)))
save_anim('good', imgs, reg)

# ---------------------------------------------------------------- life (36): 2 frames (gold / spent)
sp = G.sprites[36]
assert sp.nframes == 2 and sp.actions == {}
imgs, reg = anim_frames(36, (1, 2))
save_anim('life', imgs, reg)
# Game.addLife reads l._width on the clip stopped at frame 1 (shape 34)
meta['lifeWidth'] = G.shapes[34][1] - G.shapes[34][0]

# ---------------------------------------------------------------- bgAnim (38, turned by the code), bg (40)
imgs, reg = anim_frames(38, (1,))
save_anim('bgAnim', imgs, reg)
imgs, reg = anim_frames(40, (1,), pad=0.5)
save_anim('bg', imgs, reg)

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('anims %d, trimmed area %.2f Mpx' % (len(area), tot / 1e6))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:16]:
    print('  %-24s %8d px' % (k, v))
