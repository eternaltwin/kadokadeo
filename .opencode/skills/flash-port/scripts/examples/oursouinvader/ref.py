"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/oursouinvader/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs -> run<i>.png) with
tools/cmp_pages.py. Each item: [clip name, frame, x, y, scale(, {nested instance: frame, "__glow": [colour, alpha, blur,
strength]})]; __glow is a GlowFilter set by the code on the clip (Flash filters are in stage pixels: the blur at x2).
usage: python3 ref.py"""
import sys, json, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import numpy as np
from PIL import Image
W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'oursouinvader', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
pages = json.load(open(os.path.join(HERE, 'pages.json')))
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)
for pi, page in enumerate(pages):
    canvas = Image.new('RGBA', (600, 640), (0x33, 0x55, 0x66, 255))
    for item in page:
        name, frame, x, y, sc = item[:5]
        c = dict(item[5] if len(item) > 5 else {})
        glow = c.pop('__glow', None)
        sid = G.sid(name)
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
        m = 4 + (glow[2] / sc if glow else 0)
        ox, oy = b[0] - m, b[1] - m
        Wz, Hz = int((b[2] - b[0] + 2 * m) * G.Z) + 1, int((b[3] - b[1] + 2 * m) * G.Z) + 1
        cv = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, cv, (ox, oy))
        if glow:
            # in stage pixels: the canvas is at G.Z px per unit of the clip, shown at k px per unit (2 px per stage px)
            col, alpha, blur, strength = glow
            f = dict(type='glow', blurX=blur, blurY=blur, strength=strength,
                     color=((col >> 16) & 255, (col >> 8) & 255, col & 255, int(round(alpha * 255))))
            cv = R.apply_filter(cv, f, G.Z * 2 / k)
        im = Image.fromarray(np.clip(cv * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        im = im.resize((max(1, int(round(Wz * k / G.Z))), max(1, int(round(Hz * k / G.Z)))), Image.LANCZOS).convert('RGBA')
        canvas.alpha_composite(im, (int(round(x + ox * k)), int(round(y + oy * k))))
    canvas.convert('RGB').save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
