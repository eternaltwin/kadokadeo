"""Reference pages rendered from the SWF (swfrender, nearest sampling like the bitmaps of the game) with the layout of
pages.json (next to this file): $KKP_WORK/ktrain/check/ref<i>.png, to compare with the pages drawn by the game
(ncheck.mjs -> run<i>.png) with tools/cmp_pages.py. Each item: [clip name, frame, x, y, scale(, {nested instance:
frame}(, blend mode))] on a sand background (the shadows are multiplied).
usage: python3 ref.py"""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
sys.argv = [sys.argv[0], os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'ktrain', 'refout')]
import importlib.util
spec = importlib.util.spec_from_file_location('A', os.path.join(HERE, 'ktrain_assets.py'))
A = importlib.util.module_from_spec(spec)
spec.loader.exec_module(A)
import swfrender as R
import numpy as np
from PIL import Image
G = A.G
BG = (0xC0, 0x8A, 0x48)
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(A.W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = np.zeros((640, 600, 4), dtype=np.float32)
    canvas[..., 0], canvas[..., 1], canvas[..., 2], canvas[..., 3] = BG[0] / 255, BG[1] / 255, BG[2] / 255, 1
    for item in page:
        name, frame, x, y, sc = item[:5]
        sid = G.sid(name)
        c = {}
        for k, v in (item[5] if len(item) > 5 else {}).items():
            c[k] = v
        c[sid] = frame
        c['__noactions__'] = True
        inst = R.Instance(G, sid, ctrl=c)
        rd = R.Renderer(G, 2 * sc)
        cmds = []
        rd.collect(inst, R.IDENT, R.NOCX, set(), cmds)
        if not cmds:
            continue
        b = rd.bounds(cmds)
        k = 2 * sc
        ox, oy = b[0] - 4, b[1] - 4
        Wz, Hz = int((b[2] - b[0] + 8) * G.Z) + 1, int((b[3] - b[1] + 8) * G.Z) + 1
        cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, cv, (ox, oy))
        im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        im = im.resize((max(1, int(round(Wz * k / G.Z))), max(1, int(round(Hz * k / G.Z)))), Image.NEAREST)
        lay = np.zeros_like(canvas)
        a = np.asarray(im, dtype=np.float32) / 255.0
        px, py = int(round(x + ox * k)), int(round(y + oy * k))
        x0, y0, x1, y1 = max(0, px), max(0, py), min(600, px + a.shape[1]), min(640, py + a.shape[0])
        lay[y0:y1, x0:x1] = a[y0 - py:y1 - py, x0 - px:x1 - px]
        R.blend_into(canvas, lay, item[6] if len(item) > 6 else None)
    Image.fromarray(np.clip(canvas[..., :3] * 255 + 0.5, 0, 255).astype(np.uint8), 'RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
