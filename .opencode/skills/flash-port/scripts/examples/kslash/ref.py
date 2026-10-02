"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/kslash/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs -> run<i>.png) with
tools/cmp_pages.py. Each item: [clip name, frame, x, y, scale(, {nested clip: frame})]."""
import sys, json
import os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import numpy as np
from PIL import Image
W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kslash', '')   # SWF + FFDec exports (see rebuild_assets.sh)
Gg = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
Gp = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)
for G in (Gg, Gp):
    G.flash_replace = True
WHITE = dict(mult=[0.0, 0.0, 0.0, 1.0], add=[255, 255, 255, 0])
SPEC = {'mcShadeBody': (Gg, 182, {}), 'platText1': (Gp, 390, {}), 'platText2': (Gp, 397, {}), 'platCorner1': (Gp, 394, {}),
        'platCorner2': (Gp, 401, {})}
def find(name, extra):
    if name == 'mcMonster':
        return (Gg, 385, {341: extra['b1'], 376: extra['b1'], 336: extra['b3']})
    if name in SPEC:
        return SPEC[name]
    return (Gg, Gg.names[name], {})
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
    for item in page:
        name, frame, x, y, sc = item[:5]
        G, sid, ctrl = find(name, item[5] if len(item) > 5 else None)
        c = dict(ctrl); c[sid] = frame; c['__noactions__'] = True
        inst = R.Instance(G, sid, ctrl=c)
        rd = R.Renderer(G, 2 * sc)
        cx = WHITE if name == 'mcShadeBody' else R.NOCX
        cmds = []
        rd.collect(inst, R.IDENT, cx, set(), cmds)
        if not cmds:
            continue
        b = rd.bounds(cmds)
        k = 2 * sc
        ox, oy = b[0] - 1, b[1] - 1
        Wz, Hz = int((b[2] - b[0] + 2) * G.Z) + 1, int((b[3] - b[1] + 2) * G.Z) + 1
        cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, cv, (ox, oy))
        im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        im = im.resize((max(1, int(round(Wz * k / G.Z))), max(1, int(round(Hz * k / G.Z)))), Image.LANCZOS).convert('RGBA')
        canvas.alpha_composite(im, (int(round(x + ox * k)), int(round(y + oy * k))))
    canvas.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
