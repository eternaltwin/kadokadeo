"""The pages of pages.json rendered from the SWF (references for the pages the game draws, ccheck.mjs):
$KKP_WORK/cyclopean/check/ref<i>.png. Each item is the clip in the state the code puts it in (mcLoader on frame f,
mcElement on frame id + 1 with its nested clips on a given frame, mcInter with its bar scaled...).
usage: python3 ref.py"""
import os, sys, json, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cyclopean', '')
OUT = os.path.join(W, 'check')
os.makedirs(OUT, exist_ok=True)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
K, Z = 2, G.Z
BG = (128, 128, 128)
pages = json.load(open(os.path.join(HERE, 'pages.json')))


def inst(sid, frame, ctrl=None, timeline=False):
    if timeline:
        return R.timeline(G, sid, ctrl=ctrl)[frame - 1]
    return R.frame_states(G, sid, [frame], ctrl=ctrl)[0]


def item_inst(it):
    k = it['k']
    if k == 'loader':
        return inst(104, it['f'], {99: 1})
    if k == 'elem':
        # (the egg, sprite 168, is named "sub" too: its mcBille is forced by its id)
        ctrl = {109: 1, 165: it.get('blob', 2), 168: it.get('f', 1), 137: it.get('sid', 0) + 1}
        return inst(169, it['id'] + 1, ctrl)
    if k == 'flamb':
        return inst(113, it['f'], {109: 1})
    if k == 'inter':
        i = inst(129, 1)
        ys = it['ys'] / 100.0
        i.display[1]['matrix'] = dict(i.display[1]['matrix'], d=ys)
        i.display[9]['matrix'] = dict(i.display[9]['matrix'], ty=295 - 292 * ys)
        return i
    return inst(it['sid'], it['f'], timeline=it['sid'] in (99, 107, 80))


for pi, page in enumerate(pages):
    canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
    rd = R.Renderer(G, K)
    for it in page:
        s = it.get('s', 100) / 100.0
        r = math.radians(it.get('r', 0))
        M = dict(a=s * math.cos(r), b=s * math.sin(r), c=-s * math.sin(r), d=s * math.cos(r), tx=it['x'], ty=it['y'])
        cx = dict(mult=[1, 1, 1, 0.5], add=[0, 0, 0, 0]) if it.get('a50') else R.NOCX
        cmds = []
        rd.collect(item_inst(it), M, cx, set(), cmds)
        layer = np.zeros_like(canvas)
        rd.draw(cmds, layer, (0, 0))
        canvas = canvas * (1 - layer[..., 3:4]) + layer
    bg = np.zeros_like(canvas)
    bg[..., 0], bg[..., 1], bg[..., 2], bg[..., 3] = BG[0] / 255, BG[1] / 255, BG[2] / 255, 1
    canvas = canvas + bg * (1 - canvas[..., 3:4])
    im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA').convert('RGB')
    im.resize((600, 600), Image.LANCZOS).save(os.path.join(OUT, 'ref%d.png' % pi))
    print('ref%d' % pi)
