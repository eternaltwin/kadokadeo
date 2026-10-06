"""Reference pages rendered from the SWF (swfrender, nearest sampling like Flash's "low" quality) with the layout of
pages.json: $KKP_WORK/judocommando/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs ->
run<i>.png) with tools/cmp_pages.py."""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import numpy as np
from PIL import Image
W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'judocommando', '')
G = R.SWF(W + 'gfx.swf', W + 'shp2_gfx', Z=2)
G.flash_replace = True
G.nearest = True
DARK = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[-30, -30, -30, 0])
SPEC = {'mcHero': 611, 'mcMonsters': 1077, 'mcBonus': 119, 'mcBullet': 293, 'mcShuriken': 229, 'mcRocket': 223,
        'mcMine': 287, 'mcExplosion': 285, 'mcBlood': 45, 'fxSpark': 162, 'fxSpark2': 147, 'fxSmoke': 218, 'mcVanish': 72,
        'mcSlash': 256, 'mcSwordSlash': 238, 'fxShotImpact': 139, 'fxTwinkle': 63, 'mcNum': 257, 'partBrick': 262,
        'partWood': 243, 'fxBrickDust': 266, 'mcLifeBar': 203, 'mcLifePoint': 200, 'mcGem': 114, 'mcLevel': 197}
PARTS = {'hfr': (446,), 'bfr': (439, 682), 'gfr': (449,), 'afr': (584, 591, 598, 605)}


def frame_of(sid, f):
    return G.sprites[sid].labels[f] if isinstance(f, str) else f


def child(inst, name):
    for e in inst.display.values():
        if e['name'] == name:
            return e
    return None


pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
    for name, frame, x, y, sc, subs, vs in page:
        sid = SPEC[name]
        ctrl = {sid: frame_of(sid, frame), '__noactions__': True}
        for v, n in vs.items():
            for p in PARTS[v]:
                ctrl[p] = n
        # nested clips named in the paths: their sprite found level by level, forced to the frame
        for path in sorted(subs, key=lambda p: p.count('.')):
            inst = R.Instance(G, sid, ctrl=ctrl)
            e = None
            for nm in path.split('.'):
                e = child(inst, nm)
                if e is None:
                    break
                inst = e['inst']
            if e is not None and e['inst'] is not None:
                ctrl[e['inst'].sid] = frame_of(e['inst'].sid, subs[path])
        inst = R.Instance(G, sid, ctrl=ctrl)
        rd = R.Renderer(G, 2)
        cmds = []
        rd.collect(inst, R.IDENT, DARK if name in ('partBrick', 'partWood') else R.NOCX, {'hold', 'center'}, cmds)
        if not cmds:
            continue
        b = rd.bounds(cmds)
        ox, oy = (int(b[0]) - 2), (int(b[1]) - 2)
        Wz, Hz = (int(b[2] - ox) + 3) * 2, (int(b[3] - oy) + 3) * 2
        cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, cv, (ox, oy))
        im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
        k = 2 * sc
        im = im.resize((Wz * sc, Hz * sc), Image.NEAREST)
        canvas.alpha_composite(im, (int(round(x + ox * k)), int(round(y + oy * k))))
    canvas.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
