"""Builds the Julianus graphics for KadoKadeo from the original SWF (gfx.swf: the same symbols as the released
bulloz.swf, whose names are obfuscated).

Julianus has little nested logic: every symbol is rendered at x2 ("simple renders" pipeline) and the code picks the
frames; the nested timelines the code drives or that play on their own are separate animations:
  - hero: its "body" (5 frames chosen by the code, turned by the code); eyes: 60 frames (one per direction);
  - blow: 60 frames (one per direction) moving 3 puffs (sprite 13 twice, sprite 17) that play their 10 frames from
    the attach and stop: the puffs are animations, their matrices per blow frame go to meta.json;
  - bulle: one shape scaled by the code from 17 % to 100 % and more: rendered at 3 resolutions (the game picks the
    one closest to the scale shown, like mipmaps), pop (its burst, scaled the same way) at 2;
  - pic: frame 1 (spike ball), frame 2 (spinning spikes: the hub over its "sub", whose frame 1 is the spikes and
    frame 2 the blur, a 2 frame loop turned at random every frame), frame 3 (the orbit and its "sub" ball), frames
    4-6 (the 3 bonuses: 40 frame loops of nested timelines);
  - part (4 frames, the code picks one; drawn up to 700 %: rendered at 4 times the resolution), fxBonus (14 frames,
    the 15th removes it);
  - the 3 decor planes: 600 px bitmaps repeated twice in their 1200 px shapes, kept at their native resolution.
Sprites drawn with morph shapes (the bonus glows 46 / 60, pop, fxBonus) come from FFDec renders frame by frame
(spr4_gfx/, rebuild_assets.sh), placed by matching a frame without morph shape with the swfrender render
(julianus_swf.py).
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: julianus_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/julianus holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R
from julianus_swf import W, K, G, Z, collect
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)


pivots = {}
area = {}
meta = {}


def save_anim(name, imgs, reg):
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    w, h = imgs[0].size
    for i, im in enumerate(imgs):
        assert im.size == (w, h)
        im.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(reg[0] / w, 6), round(reg[1] / h, 6)]
    a = 0
    for im in imgs:
        bb = im.split()[3].getbbox()
        if bb:
            a += (bb[2] - bb[0]) * (bb[3] - bb[1])
    area[name] = a


def render(cmd_lists, pad=0.5, k=K):
    """command lists drawn on one common canvas (x4, reduced to x k). Returns (images, registration in px)."""
    rd = R.Renderer(G, k)
    bb = None
    for cmds in cmd_lists:
        b = rd.bounds(cmds)
        if b:
            bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    step = 1.0 / k
    ox = math.floor((bb[0] - pad) / step) * step
    oy = math.floor((bb[1] - pad) / step) * step
    ex = math.ceil((bb[2] + pad) / step) * step
    ey = math.ceil((bb[3] + pad) / step) * step
    Wz, Hz = int(round((ex - ox) * Z)), int(round((ey - oy) * Z))
    w, h = int(round((ex - ox) * k)), int(round((ey - oy) * k))
    imgs = []
    for cmds in cmd_lists:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        imgs.append(im.resize((w, h), Image.LANCZOS).convert('RGBA'))
    return imgs, (-ox * k, -oy * k)


def states(sid, frames, ctrl=None, keep=None, drop=None):
    """the sprite stopped on each frame (nested clips at their first frame unless forced by ctrl), only the depths
    `keep` / without the depths `drop`"""
    out = []
    for s in R.frame_states(G, sid, frames, ctrl=ctrl):
        for d in list(s.display):
            if (keep is not None and d not in keep) or (drop is not None and d in drop):
                del s.display[d]
        out.append(s)
    return out


def anim(name, insts, pad=0.5, k=K):
    imgs, reg = render([collect(i) for i in insts], pad, k)
    save_anim(name, imgs, reg)
    return imgs, reg


def decompose(m):
    """a matrix without skew -> x, y, _xscale, _yscale, _rotation (the y scale carries a mirror)"""
    a, b, c, d = m['a'], m['b'], m['c'], m['d']
    rot = math.atan2(b, a)
    sx = math.hypot(a, b)
    sy = (a * d - b * c) / sx
    assert abs(c + sy * math.sin(rot)) < 2e-3 and abs(d - sy * math.cos(rot)) < 2e-3, m
    return [round(m['tx'], 4), round(m['ty'], 4), round(sx * 100, 4), round(sy * 100, 4), round(math.degrees(rot), 4)]


def leaf_frames(sid, frames):
    return [[('leaf', sid, f, R.IDENT, R.NOCX)] for f in frames]


# ---------------------------------------------------------------- hero
hero = R.Instance(G, 10).display[1]
assert hero['name'] == 'body' and hero['inst'].sid == 9
meta['body'] = decompose(hero['matrix'])
anim('body', states(9, range(1, 6)))
anim('eyes', states(3, range(1, 61)))
# blow: the puffs (depths 1 and 3: sprite 13, depth 5: sprite 17) stop on their frame 10
bl = states(18, range(1, 61))
for s in bl:
    assert sorted(s.display) == [1, 3, 5]
    assert all(e['cx'] == R.NOCX for e in s.display.values())
assert [bl[0].display[d]['inst'].sid for d in (1, 3, 5)] == [13, 13, 17]
meta['blow'] = [[decompose(s.display[d]['matrix']) for d in (1, 3, 5)] for s in bl]
anim('puff', R.timeline(G, 13, 10))
anim('puffEnd', R.timeline(G, 17, 10))
assert G.sprites[13].actions.get(10) and G.sprites[17].actions.get(10)   # stop()

# ---------------------------------------------------------------- bubbles
BULLE_LEVELS = [0.25, 0.5, 1.0]
for lv in BULLE_LEVELS:
    anim('bulle%d' % int(lv * 100), [R.Instance(G, 20)], k=K * lv)
meta['bulleLevels'] = BULLE_LEVELS
# pop: 9 frames, the 9th removes it (this.removeMovieClip())
POP_LEVELS = [0.25, 0.5]
for lv in POP_LEVELS:
    imgs, reg = render(leaf_frames(95, range(1, 9)), k=K * lv)
    save_anim('pop%d' % int(lv * 100), imgs, reg)
meta['popLevels'] = POP_LEVELS

# ---------------------------------------------------------------- pics
anim('pic0', states(75, [1]))
p2 = R.frame_states(G, 75, [2])[0].display
assert sorted(p2) == [1, 9] and p2[1]['name'] == 'sub' and p2[1]['inst'].sid == 35 and p2[1]['matrix'] == R.IDENT
anim('pic1Hub', states(75, [2], keep={9}))
anim('pic1Spikes', states(35, [1]))
# sub frame 2: sprite 34 (its frame 1 turns "blur" at random, its frame 2 goes back to frame 1) holding sprite 33,
# 2 shapes playing in turn
d34 = R.frame_states(G, 35, [2])[0].display
assert sorted(d34) == [1] and d34[1]['inst'].sid == 34 and d34[1]['matrix'] == R.IDENT
assert R.Instance(G, 34).display[1]['name'] == 'blur' and R.Instance(G, 34).display[1]['matrix'] == R.IDENT
anim('pic1Blur', states(33, [1, 2]))
p3 = R.frame_states(G, 75, [3])[0].display
assert sorted(p3) == [1, 2] and p3[2]['name'] == 'sub' and p3[2]['inst'].sid == 39
anim('pic2Orbit', states(75, [3], keep={1}))
anim('pic2Ball', [R.Instance(G, 39)])
meta['pic2Sub'] = decompose(p3[2]['matrix'])
for i, f in enumerate((4, 5, 6)):
    d = R.frame_states(G, 75, [f])[0].display
    assert sorted(d) == [1] and d[1]['matrix'] == R.IDENT
    sid = d[1]['inst'].sid
    assert G.sprites[sid].nframes == 40
    anim('bonus%d' % i, R.timeline(G, sid, 40))

# ---------------------------------------------------------------- particles and effects
anim('part', states(100, range(1, 5)), k=K * 4)
imgs, reg = render(leaf_frames(89, range(1, 15)))
save_anim('fxBonus', imgs, reg)

# ---------------------------------------------------------------- decor (bitmaps at their native resolution)
# each plane: a 1200 px shape filled with one 600 px bitmap at x = 0 and x = 600 (read in svg_gfx), its _width is
# the shape's (the code wraps it every _width / 2)
DECOR = {'bg2': (110, 109, [(108, 0, 0)]), 'bg1': (104, 103, [(101, 0, 0), (102, 0, 267.5)]), 'bg0': (107, 106, [(105, 0, 0)])}
meta['decor'] = {}
for name, (sid, shp, fills) in DECOR.items():
    e = R.Instance(G, sid).display
    assert len(e) == 1 and list(e.values())[0]['char'] == shp and list(e.values())[0]['matrix'] == R.IDENT
    svg = open(W + 'svg_gfx/%d.svg' % shp).read()
    parts = []
    for i, (bid, x, y) in enumerate(fills):
        for tx in (0, 600):
            assert 'patternTransform="matrix(1.0, 0.0, 0.0, 1.0, %.1f, %s)"' % (x + tx, repr(float(y))) in svg, (shp, x + tx, y)
        ext = 'jpg' if os.path.exists(W + 'img_gfx/%d.jpg' % bid) else 'png'
        im = Image.open(W + 'img_gfx/%d.%s' % (bid, ext)).convert('RGBA')
        assert im.width == 600
        an = '%s_%d' % (name, i)
        save_anim(an, [im], (0, 0))
        parts.append([an, x, y])
    r = G.shapes[shp]
    meta['decor'][name] = {'width': r[1] - r[0], 'parts': parts}
    assert r[0] == 0 and r[1] == 1200

# ---------------------------------------------------------------- start screen (julianus_artwork.py, not packed)
# the old thumbnail draws the characters 1.6 times bigger than the game: rendered at that size
ART = os.path.join(OUT, 'art')
if os.path.isdir(ART):
    shutil.rmtree(ART)
os.makedirs(ART)
art = {}
for name, insts in (('body', states(9, [1])), ('eyes', states(3, [46])), ('pic0', states(75, [1])),
                    ('bonus0', R.timeline(G, 53, 1)), ('bulle', [R.Instance(G, 20)])):
    imgs, reg = render([collect(i) for i in insts], k=K * 1.6)
    imgs[0].save(os.path.join(ART, name + '.png'))
    art[name] = reg
json.dump(art, open(os.path.join(ART, 'reg.json'), 'w'))

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=1, sort_keys=True)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'))
tot = sum(area.values())
print('anims %d, texture area %d px' % (len(pivots), tot))
for n, a in sorted(area.items(), key=lambda x: -x[1])[:12]:
    print('  %-14s %8d' % (n, a))
