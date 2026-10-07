"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/happyptitank/check/ref<i>.png, to compare with the pages drawn by the game (hpages.mjs -> run<i>.png) with
tools/cmp_pages.py. Each item: [symbol id, frame, x, y, scale]: the symbol at that frame (its nested clips at their
first frame), its origin at (x, y) of the 300 x 300 stage, drawn x2.
usage: python3 ref.py"""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import numpy as np
from PIL import Image
W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'happyptitank', '')
G = R.SWF(W + 'tank.swf', W + 'shp4_tank', Z=4)
G.flash_replace = True
G.nested_masks = True
rd = R.Renderer(G, 2)
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = np.zeros((640 * 2, 600 * 2, 4), dtype=np.float32)
    canvas[...] = np.array([0x33 / 255, 0x55 / 255, 0x66 / 255, 1], dtype=np.float32)
    for sid, frame, x, y, sc in page:
        inst = R.Instance(G, sid, ctrl={sid: frame, '__noactions__': True})
        cmds = []
        rd.collect(inst, dict(a=sc, b=0.0, c=0.0, d=sc, tx=x, ty=y), R.NOCX, set(), cmds)
        rd.draw(cmds, canvas, (0, 0))
    im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
    im = im.resize((600, 640), Image.LANCZOS)
    im.save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d' % pi)
