"""Builds the Cyclopean graphics for KadoKadeo from the original SWF (gfx.swf: same symbols as the released
temple.swf, whose names are obfuscated).

Cyclopean has little nested logic: every symbol is rendered at x2 ("simple renders" pipeline) and the code picks
frames; the few nested timelines that play on their own are rendered as separate animations placed by the code:
  - mcPiou (the chick, 18 frames looping), mcBille (7 colours), mcLightFlip (2 frames looping), partSpark (8 frames,
    the 9th removes it), partImpact, mcPentacle, mcMiniPiou (blinks: frames 11-13 are empty);
  - mcElement: frames 1-3 (gems) without their nested mcLightFlip (playing) and the 4 smoke blobs of sprite 166
    (each a sprite 165 jumping to a random frame: anims blob0..3, their matrices baked); frame 4 (time); frame 5
    (egg: sprite 168 playing its 17 frames, its mcBille "sub" set by the code: one anim per colour, egg1..7);
  - partFlamb: its dot (3 frames, chosen by the code) without its nested mcLightFlip;
  - mcLoader: its pieces (ring + tinted pentacle, the quarter disc turned by the timeline, the two covers, the rune
    ring "wh" turned by the code), the timeline as numbers in meta.json;
  - mcInter: the gauge (masked by its bar, scaled by the code), the caps;
  - mcBurst: 71 frames (the 72nd removes it), cropped to what the screen shows (it is placed 6 px from the
    bottom-right corner of the 300x300 stage);
  - mcText / mcBgText: the 128x128 textures Cs.texturize tiles into the level and background bitmaps, at the native
    resolution of those bitmaps (1 px per Flash pixel: tileText / tileBg);
  - mcFirst / mcBase (the pieces Game.genLevel carves the cave with) and their $a anchors: the outlines of their
    shapes flattened into polygons, their bounds and the anchors' matrices, written to meta.json (the game
    rasterizes them itself: the level is gameplay, read pixel by pixel by the collisions).
Writes <out>/src (images), <out>/pivots.json and <out>/meta.json.
usage: cyclopean_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/cyclopean holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cyclopean', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z

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


def collect(inst, cx=R.NOCX, k=K):
    out = []
    R.Renderer(G, k).collect(inst, R.IDENT, cx, set(), out)
    return out


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


def anim(name, insts, pad=0.5, cx=R.NOCX):
    imgs, reg = render([collect(i, cx) for i in insts], pad)
    save_anim(name, imgs, reg)
    return imgs, reg


def mat(m):
    return [m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']]


def rotation(m):
    # Flash's _rotation of a clip placed by a timeline: atan2(b, a) of its matrix, in degrees
    return math.degrees(math.atan2(m['b'], m['a']))


# ---------------------------------------------------------------- characters
anim('piou', R.timeline(G, 99))                          # gotoAndPlay(1) on frame 18: an 18 frame loop
anim('bille', states(137, range(1, 8)))
anim('lightflip', states(109, [1, 2]))
anim('spark', R.timeline(G, 107)[:8])                    # frame 9: empty, obj.kill()
anim('impact', states(115, [1]))
anim('pentacle', states(84, [1]))
anim('miniPiou', states(10, range(1, 11)))               # frames 11-13: empty (the blink)
# partFlamb: the coloured dot (depths 4 / 5); its mcLightFlip (depth 1, x 2.6667) is a child playing on its own
anim('flamb', states(113, [1, 2, 3], drop={1}))
e = R.Instance(G, 113).display[1]
meta['flambLight'] = mat(e['matrix'])

# ---------------------------------------------------------------- mcElement
# frames 1-3: disc + dot (depths 4-6); the mcLightFlip of depth 1 and sprite 166 of depth 7 are children; frame 4:
# the time bonus (shape 167 at depth 1)
anim('elem', states(169, [1, 2, 3], drop={1, 7}) + states(169, [4]))
assert [d for d in R.frame_states(G, 169, [4])[0].display] == [1]
el = R.Instance(G, 169).display
meta['elemLight'] = mat(el[1]['matrix'])
meta['elemSmoke'] = mat(el[7]['matrix'])
# the 4 sprites 165 of sprite 166 (depths 1, 3, 5, 7), each on its own frame: anims blob0..3, 27 frames each
smoke_depths = sorted(R.Instance(G, 166).display)
assert smoke_depths == [1, 3, 5, 7]
for k, d in enumerate(smoke_depths):
    anim('blob%d' % k, [states(166, [1], ctrl={165: f}, keep={d})[0] for f in range(1, 28)])
# frame 5: sprite 168 (17 frames, playing) with its mcBille "sub" on the colour the code sets
eggs = []
for c in range(1, 8):
    eggs.append([collect(s) for s in R.timeline(G, 168, ctrl={'sub': c})])
imgs, reg = render([c for e_ in eggs for c in e_])
for c in range(7):
    save_anim('egg%d' % (c + 1), imgs[c * 17:(c + 1) * 17], reg)

# ---------------------------------------------------------------- mcLoader
ld = R.Instance(G, 104).display
anim('loaderBase', states(104, [1], keep={1, 2}))
anim('loaderQuarter', [R.Instance(G, 86)])
anim('loaderCover', states(104, [1, 26, 51], keep={10}))
anim('loaderWh', [R.Instance(G, 102)])
tl = R.timeline(G, 104)
meta['loader'] = {
    # per frame: rotation of the two quarter discs (depth 4: the mask of depth 6), cover frame (1: shape 87, 2: shape 103,
    # 3: shape 85, 0: none)
    'q4': [round(rotation(s.display[4]['matrix']), 4) for s in tl],
    'q6': [round(rotation(s.display[6]['matrix']), 4) for s in tl],
    'cover': [{87: 1, 103: 2, 85: 3}[s.display[10]['char']] if 10 in s.display else 0 for s in tl],
    'piou': mat(ld[11]['matrix']),
    'wh': mat(ld[38]['matrix']),
}
# depth 4 is a mask (clipDepth 8) on depth 6, turned by quarters: an axis-aligned quadrant (a scissor in the game)
assert all(s.display[4]['clip'] == 8 and s.display[6]['clip'] is None for s in tl)
assert all(abs(q / 90 - round(q / 90)) < 1e-3 for q in meta['loader']['q4'])
for s in tl:
    for d in (4, 6):
        m = s.display[d]['matrix']
        sc = math.hypot(m['a'], m['b'])
        assert abs(sc - 1) < 0.002 and abs(m['a'] - m['d']) < 1e-3 and abs(m['b'] + m['c']) < 1e-3, m

# ---------------------------------------------------------------- mcInter
it = R.Instance(G, 129).display
# the bar (sprite 124: a white rectangle) is the mask of the gauge (shape 126): never drawn
assert it[1]['clip'] == 5 and it[1]['name'] == 'bar'
anim('interFrame', states(129, [1], keep={4}))
anim('interCap', [R.Instance(G, 128)])
meta['inter'] = {'bar': mat(it[1]['matrix']), 'cap': mat(it[7]['matrix']), 'barUp': mat(it[9]['matrix']),
                 # sprite 124's bounds (bar._height = 292 * _yscale / 100), the rectangle of the mask
                 'barW': G.shapes[123][1] - G.shapes[123][0], 'barH': G.shapes[123][3] - G.shapes[123][2]}
assert G.shapes[123][0] == 0 and G.shapes[123][3] == 0

# ---------------------------------------------------------------- mcBurst
# placed at (294, 294) on the 300x300 stage: only x, y < 6 of the clip are seen
bt = R.timeline(G, 80)[:71]
imgs, reg = render([collect(s) for s in bt])
cx, cy = int(math.ceil(reg[0] + 7 * K)), int(math.ceil(reg[1] + 7 * K))
imgs = [im.crop((0, 0, min(cx, im.width), min(cy, im.height))) for im in imgs]
save_anim('burst', imgs, reg)

# ---------------------------------------------------------------- textures of the bitmaps (1 px per Flash pixel)
for name, sid in (('tileText', 170), ('tileBg', 118)):
    imgs, reg = render([collect(R.Instance(G, sid), k=1)], pad=0, k=1)
    im = imgs[0]
    assert im.size == (128, 128) and reg == (0, 0), (im.size, reg)
    a = np.asarray(im)[..., 3]
    print(name, 'alpha', a.min(), a.max())
    save_anim(name, [im], (0, 0))


# ---------------------------------------------------------------- level pieces (gameplay geometry)
def svg_paths(cid):
    """the fill paths of a shape (FFDec SVG export): a list of path elements (filled even-odd, united), each a
    list of closed contours [(x, y)...] with the quadratic curves flattened (deviation < 0.02 px)"""
    txt = open(W + 'svg_gfx/%d.svg' % cid).read()
    out = []
    for d in re.findall(r'<path d="([^"]+)"[^>]*fill="#', txt):
        toks = re.findall(r'[MLQ]|-?\d+(?:\.\d+)?', d)
        contours = []
        cur = None
        cmd = None
        i = 0
        x = y = 0.0
        while i < len(toks):
            t = toks[i]
            if t in 'MLQ':
                cmd = t
                i += 1
                continue
            if cmd == 'M':
                x, y = float(toks[i]), float(toks[i + 1])
                i += 2
                cur = [(x, y)]
                contours.append(cur)
                cmd = 'L'
            elif cmd == 'L':
                x, y = float(toks[i]), float(toks[i + 1])
                i += 2
                cur.append((x, y))
            elif cmd == 'Q':
                cx_, cy_, nx, ny = (float(v) for v in toks[i:i + 4])
                i += 4
                dev = math.hypot(x - 2 * cx_ + nx, y - 2 * cy_ + ny) / 4
                n = max(1, int(math.ceil(math.sqrt(dev / 0.02))))
                for s in range(1, n + 1):
                    t_ = s / n
                    u = 1 - t_
                    cur.append((u * u * x + 2 * u * t_ * cx_ + t_ * t_ * nx, u * u * y + 2 * u * t_ * cy_ + t_ * t_ * ny))
                x, y = nx, ny
        cs = []
        for c in contours:
            if len(c) > 1 and c[0] == c[-1]:
                c = c[:-1]
            # coordinates in 1/64 px (exact binary fractions)
            q = []
            for (px, py) in c:
                p = (int(round(px * 64)), int(round(py * 64)))
                if not q or q[-1] != p:
                    q.append(p)
            if len(q) >= 3:
                cs.append([v for p in q for v in p])
        out.append(cs)
    return out


def piece(sid, frames):
    res = []
    for f in frames:
        inst = R.frame_states(G, sid, [f])[0]
        shape = None
        anchors = {}
        dup = []
        for d, e in sorted(inst.display.items()):
            if e['name'] and e['name'].startswith('$a'):
                assert e['inst'] is not None and e['inst'].sid == 121
                m = e['matrix']
                a = [m['tx'], m['ty'], rotation(m)] + mat(m)[:4]
                # two children of the same name (frame 9: $a1 twice): the name finds the lowest depth
                if e['name'] in anchors:
                    dup.append(a)
                else:
                    anchors[e['name']] = a
            else:
                assert shape is None and e['inst'] is None and e['matrix'] == R.IDENT, (sid, f, d, e)
                shape = e['char']
        # Std.getVar(mc, "$a" + i) for i = 0..6, until one is missing
        al = []
        for i in range(7):
            if '$a%d' % i not in anchors:
                break
            al.append(anchors['$a%d' % i])
        extra = sorted(set(anchors) - {'$a%d' % i for i in range(len(al))})
        res.append({'shape': shape, 'rect': G.shapes[shape], 'polys': svg_paths(shape), 'anchors': al,
                    # anchors the list does not hold (still children of the clip: getBounds and hitTest see them)
                    'others': [anchors[n] for n in extra] + dup})
    return res


meta['first'] = piece(122, [1])[0]
meta['bases'] = piece(192, range(1, G.sprites[192].nframes + 1))
meta['anchorShape'] = {'rect': G.shapes[120], 'polys': svg_paths(120)}
assert R.Instance(G, 121).display[1]['matrix'] == R.IDENT and R.Instance(G, 121).display[1]['char'] == 120
for p in [meta['first']] + meta['bases']:
    print('piece shape %d: %d anchors (+%d), %d paths, %d points' % (
        p['shape'], len(p['anchors']), len(p['others']), len(p['polys']), sum(len(c) // 2 for pp in p['polys'] for c in pp)))

json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=1, sort_keys=True)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'))
tot = sum(area.values())
print('anims %d, texture area %d px' % (len(pivots), tot))
for n, a in sorted(area.items(), key=lambda x: -x[1])[:10]:
    print('  %-14s %8d' % (n, a))
