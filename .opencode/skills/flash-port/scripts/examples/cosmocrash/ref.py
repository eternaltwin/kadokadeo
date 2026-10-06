"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/cosmocrash/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs -> run<i>.png) with
tools/cmp_pages.py. Each item: [clip name, frame, x, y, scale(, {nested instance: frame})]. The colour copies of
mcFolk / mcCosmo and the decor pictures are the asset script's (its SWF model, with the copies).
usage: python3 ref.py"""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
sys.argv = [sys.argv[0], os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cosmocrash', 'refout')]
import importlib.util
spec = importlib.util.spec_from_file_location('A', os.path.join(HERE, 'cosmocrash_assets.py'))
A = importlib.util.module_from_spec(spec)
spec.loader.exec_module(A)
import swfrender as R
import numpy as np
from PIL import Image
G = A.G
SPEC = {n: G.sid(n) for n in ('mcHero', 'mcFolk', 'mcCosmo', 'mcStar', 'partDust', 'mcGyro', 'mcPlat', 'mcShuttle', 'mcJeep',
                              'mcCanon', 'mcWheel', 'mcShot', 'mcExplosion', 'mcOnde', 'partSpark', 'partHero', 'fxScore', 'mcHor')}
for k in (1, 2, 3):
    SPEC['mcFolk%d' % k] = A.CLONES[k][0]
    SPEC['mcCosmo%d' % k] = A.CLONES[k][1]
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(A.W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
    for item in page:
        name, frame, x, y, sc = item[:5]
        c = dict(item[5] if len(item) > 5 else {})
        if name.startswith('decor'):
            sid = 105
            c[104] = frame
        else:
            sid = SPEC[name]
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
        im = im.resize((max(1, int(round(Wz * k / G.Z))), max(1, int(round(Hz * k / G.Z)))), Image.LANCZOS).convert('RGBA')
        canvas.alpha_composite(im, (int(round(x + ox * k)), int(round(y + oy * k))))
    canvas.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
