"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/magmax/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs -> run<i>.png) with
tools/cmp_pages.py. Each item: [clip name, frame, x, y, scale(, {nested instance: frame})]."""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from magmax_swf import W, G, Gp, R
import numpy as np
from PIL import Image
RED = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[255, 0, 0, 0])
SPEC = {'hero': (G, 219), 'death': (G, 62), 'monster': (G, 189), 'tir': (G, 211), 'tirRed': (G, 211), 'plop': (G, 108),
        'plopRed': (G, 108), 'heliPart': (G, 115), 'bonus': (G, 96), 'boum': (G, 239), 'blam': (G, 13),
        'comment': (G, 36), 'bg': (Gp, 222)}
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
    for item in page:
        name, frame, x, y, sc = item[:5]
        X, sid = SPEC[name]
        c = dict(item[5] if len(item) > 5 else {})
        c[sid] = frame
        c['__noactions__'] = True
        inst = R.Instance(X, sid, ctrl=c)
        rd = R.Renderer(X, 2 * sc)
        cmds = []
        rd.collect(inst, R.IDENT, RED if name.endswith('Red') else R.NOCX, set(), cmds)
        if not cmds:
            continue
        b = rd.bounds(cmds)
        k = 2 * sc
        ox, oy = b[0] - 1, b[1] - 1
        Wz, Hz = int((b[2] - b[0] + 2) * X.Z) + 1, int((b[3] - b[1] + 2) * X.Z) + 1
        cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, cv, (ox, oy))
        im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        im = im.resize((max(1, int(round(Wz * k / X.Z))), max(1, int(round(Hz * k / X.Z)))), Image.LANCZOS).convert('RGBA')
        canvas.alpha_composite(im, (int(round(x + ox * k)), int(round(y + oy * k))))
    canvas.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
