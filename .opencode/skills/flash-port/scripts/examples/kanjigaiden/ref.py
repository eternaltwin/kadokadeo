"""Comparison pages of Kanji Gaiden: lays out the clips the game draws (pages.json, next to this file) and renders
them from the SWF (swfrender) into $KKP_WORK/kanjigaiden/check/ref<i>.png, to compare with the pages drawn by the game
(ncheck.mjs -> run<i>.png) with tools/cmp_pages.py. Each item of pages.json: [clip of the game, frame, x, y, scale,
{path of a nested clip: frame}]. The SWF side is the original symbol with its nested frames forced, the colour of the
plane for the monkeys of the planes 1 and 2, its filters in stage pixels (Flash does not scale them with the clip).
The score is left out (its text field is drawn by the asset script, swfrender has no text).
usage: python3 ref.py"""
import sys, json, os, copy
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
sys.argv = [sys.argv[0], os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kanjigaiden', 'refout')]
import swfrender as R
import numpy as np
from PIL import Image

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kanjigaiden', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
G.inner_filters = True
G.blur_filters = True
PLAN_CX = [R.NOCX] + [dict(mult=[m, m, m, 1.0], add=[int(p / 100.0 * 0xD4), int(p / 100.0 * 0xFB), int(p / 100.0 * 0xA2), 0])
                      for p, m in ((25, 0.75), (50, 0.5))]
MONKEY_N = {1: 81, 2: 94, 3: 107}

# items: (game clip, frame, scale, {game path: frame}, (SWF sid, {sid: frame}), colour)
items = []
for f in (1, 20, 46, 47, 48, 50, 53):
    items.append(('hero', 1, 0.45, {'smc': f, 'smc.smc': 1, 'smc.smc.smc': 1}, (33, {32: f, 27: 1, 21: 1}), R.NOCX))
for t in (2, 3, 4):
    items.append(('hero', 1, 0.45, {'smc': 1, 'smc.smc': 1, 'smc.smc.smc': t}, (33, {32: 1, 27: 1, 21: t}), R.NOCX))
for t in (1, 2, 3, 4):
    for sc in (1.2, 0.7):
        items.append(('kunai', 1, sc, {'smc': t}, (16, {16: 1, 14: t}), R.NOCX))
for t in (1, 4):
    for bf in (1, 4, 7):
        items.append(('kunai', 2, 1.0, {'smc': bf, 'smc.smc': t}, (16, {16: 2, 15: bf, 14: t}), R.NOCX))
for t in range(1, 5):
    for f in (1, 6, 12, 17, 20, 24, 28):
        items.append(('bonus%d' % t, f, 0.8, {}, (43, {43: f, 42: t}), R.NOCX))
for f in (1, 5, 9, 16):
    items.append(('warning', f, 1.0, {}, (50, {50: f}), R.NOCX))
MONKEY_FRAMES = (1, 15, 35, 50, 65, 80, 90, 95, 110, 130, 148, 175)
for d in (1, 2, 3):
    s = MONKEY_N[d]
    for f in MONKEY_FRAMES:
        items.append(('monkeyD', d, 0.6, {'smc': f, 'smc.smc': 1 + (f % 8)}, (108, {108: d, s: f, 58: 1 + (f % 8)}), R.NOCX))
for p, sc in ((0, 0.5), (1, 0.25), (2, 0.125)):
    for d in (1, 2, 3):
        s = MONKEY_N[d]
        for f in (1, 50, 80, 110, 130, 175):
            for k in ((1, 5) if p == 0 else (3,)):
                items.append(('monkey%d' % p, d, sc, {'smc': f, 'smc.smc': k}, (108, {108: d, s: f, 58: k}), PLAN_CX[p]))
items.append(('fg', 1, 0.5, {}, (38, {38: 1}), R.NOCX))
items.append(('mcBg', 1, 0.3, {}, (128, {128: 1}), R.NOCX))


def stage_filters(sc):
    """the sprites with their filters divided by the scale of the page (Flash filters are in stage pixels)"""
    sp = copy.deepcopy(G.sprites)
    for sd in sp.values():
        for ops in sd.frames:
            for k, v in ops:
                if k == 'place' and v.get('filters'):
                    for f in v['filters']:
                        for key in ('blurX', 'blurY', 'distance'):
                            if key in f:
                                f[key] = f[key] / sc
    return sp


SPRITES = G.sprites
CACHE = {}


def render(item):
    name, frame, sc, sub, (sid, ctrl), cx = item
    key = sc
    if key not in CACHE:
        CACHE[key] = stage_filters(sc)
    G.sprites = CACHE[key]
    c = dict(ctrl)
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    k = 2 * sc
    rd = R.Renderer(G, k)
    cmds = []
    rd.collect(inst, R.IDENT, cx, set(), cmds)
    G.sprites = SPRITES
    if not cmds:
        return None
    b = rd.bounds(cmds)
    ox, oy = b[0] - 4 / sc, b[1] - 4 / sc
    Wz, Hz = int((b[2] - b[0] + 8 / sc) * G.Z) + 1, int((b[3] - b[1] + 8 / sc) * G.Z) + 1
    G.sprites = CACHE[key]
    cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
    rd.draw(cmds, cv, (ox, oy))
    G.sprites = SPRITES
    im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    im = im.resize((max(1, int(round(Wz * k / G.Z))), max(1, int(round(Hz * k / G.Z)))), Image.LANCZOS).convert('RGBA')
    return im, (-ox * k, -oy * k)


# layout: rows of items, in the order above, on pages of 600 x 640
pages, refs = [], []
x = y = rowh = 0
page = canvas = None
for it in items:
    r = render(it)
    if r is None:
        continue
    im, (rx, ry) = r
    if page is None or x + im.width > 600:
        x, y, rowh = 0, y + rowh, 0
    if page is None or y + im.height > 640:
        page, canvas = [], Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
        pages.append(page)
        refs.append(canvas)
        x = y = rowh = 0
    canvas.alpha_composite(im, (x, y)) if im.width <= 600 and im.height <= 640 else canvas.alpha_composite(im.crop((0, 0, 600, 640)), (x, y))
    page.append([it[0], it[1], round(x + rx, 2), round(y + ry, 2), it[2], it[3]])
    x += im.width
    rowh = max(rowh, im.height)
json.dump(pages, open(os.path.join(HERE, 'pages.json'), 'w'), separators=(',', ':'))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for i, c in enumerate(refs):
    c.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % i))
print('%d pages' % len(refs))
