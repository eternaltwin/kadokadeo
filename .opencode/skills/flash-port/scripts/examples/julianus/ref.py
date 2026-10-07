"""The pages of pages.json rendered from the SWF (references for the pages the game draws, jcheck.mjs):
$KKP_WORK/julianus/check/ref<i>.png. Each item is the clip in the state the code puts it in (hero with its body on a
frame and turned, eyes / blow on a direction frame with the puffs on a frame, pic on its frame with its sub turned,
blurred or moved, the bubble and its burst scaled...).
usage: python3 ref.py"""
import os, sys, json, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import numpy as np
from PIL import Image
from julianus_swf import W, K, G, Z, R

OUT = os.path.join(W, 'check')
os.makedirs(OUT, exist_ok=True)
BG = (128, 128, 128)
pages = json.load(open(os.path.join(HERE, 'pages.json')))


def turned(m, deg):
    """the matrix of a child (no rotation in the SWF) turned by deg (Flash's _rotation)"""
    r = math.radians(deg)
    sx = math.hypot(m['a'], m['b'])
    sy = math.hypot(m['c'], m['d'])
    return dict(m, a=sx * math.cos(r), b=sx * math.sin(r), c=-sy * math.sin(r), d=sy * math.cos(r))


def hero(it):
    i = R.frame_states(G, 10, [1], ctrl={9: it['bf']})[0]
    e = i.display[1]
    e['matrix'] = turned(e['matrix'], it['r'])
    return i


def blow(it):
    return R.frame_states(G, 18, [it['f']], ctrl={13: it['pf'], 17: it['pf']})[0]


def eyes(it):
    return R.frame_states(G, 3, [it['f']])[0]


def item(it):
    """[(instance or leaf command maker)]"""
    k = it['k']
    if k == 'hero':
        return [hero(it)]
    if k == 'eyes':
        return [eyes(it)]
    if k == 'blow':
        return [blow(it)]
    if k == 'full':
        return [hero(it), blow(it), eyes(it)]
    if k == 'pic':
        if it['f'] == 2:
            i = R.frame_states(G, 75, [2], ctrl={35: 2 if it.get('blur') else 1, 33: it.get('bf', 1)})[0]
            sub = i.display[1]
            if it.get('blur'):
                bl = sub['inst'].display[1]['inst'].display[1]
                bl['matrix'] = turned(bl['matrix'], it['br'])
            else:
                sub['matrix'] = turned(sub['matrix'], it['r'])
            return [i]
        i = R.frame_states(G, 75, [it['f']])[0]
        if it['f'] == 3:
            i.display[2]['matrix'] = dict(i.display[2]['matrix'], tx=it['dx'], ty=it['dy'])
        return [i]
    if k == 'bonus':
        return [R.timeline(G, (53, 67, 74)[it['n']], it['f'])[it['f'] - 1]]
    if k == 'bulle':
        return [R.Instance(G, 20)]
    if k == 'pop':
        return [('leaf', 95, it['f'])]
    if k == 'fxBonus':
        return [('leaf', 89, it['f'])]
    if k == 'part':
        return [R.frame_states(G, 100, [it['f']])[0]]
    raise KeyError(k)


for pi, page in enumerate(pages):
    canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
    rd = R.Renderer(G, K)
    for it in page:
        s = it.get('size', it.get('s', 100))
        xs, ys = it.get('xs', s) / 100.0, it.get('ys', s) / 100.0
        M = dict(a=xs, b=0, c=0, d=ys, tx=it['x'], ty=it['y'])
        for x in item(it):
            if isinstance(x, tuple):
                cmds = [('leaf', x[1], x[2], M, R.NOCX)]
            else:
                cmds = []
                rd.collect(x, M, R.NOCX, set(), cmds)
            layer = np.zeros_like(canvas)
            rd.draw(cmds, layer, (0, 0))
            canvas = canvas * (1 - layer[..., 3:4]) + layer
    bg = np.zeros_like(canvas)
    bg[..., 0], bg[..., 1], bg[..., 2], bg[..., 3] = BG[0] / 255, BG[1] / 255, BG[2] / 255, 1
    canvas = canvas + bg * (1 - canvas[..., 3:4])
    im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA').convert('RGB')
    im.resize((600, 600), Image.LANCZOS).save(os.path.join(OUT, 'ref%d.png' % pi))
    print('ref%d' % pi)
