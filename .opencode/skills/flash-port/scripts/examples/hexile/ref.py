"""The pages of pages.json rendered from the SWF (references for the pages the game draws, hcheck.mjs):
$KKP_WORK/hexile/check/ref<i>.png. Clips by swfrender, in the state the code puts them in (mcHex frame, base raised
and on frame n + 1, soldiers in the team colour and on whole pixels like Socle.register, colour transforms of
rover / the blink); the text fields by FFDec, from copies of gfx.swf holding the texts.
usage: python3 ref.py"""
import os, sys, json, math, shutil, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
sys.argv = [sys.argv[0], os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'hexile', 'refout')]
# the asset script's helpers (it also rebuilds its out dir: a scratch one here)
import importlib.util
spec = importlib.util.spec_from_file_location('A', os.path.join(HERE, 'hexile_assets.py'))
A = importlib.util.module_from_spec(spec)
spec.loader.exec_module(A)
import numpy as np
from PIL import Image
import swfrender as R

OUT = os.path.join(A.W, 'check')
os.makedirs(OUT, exist_ok=True)
K, Z = A.K, A.Z
BG = (128, 128, 128)
pages = json.load(open(os.path.join(HERE, 'pages.json')))
TEAM = {0: 1, 1: 2}


def soldier_entries(inst):
    return [e for e in inst.display.values() if e['inst'] is not None and e['inst'].sid == A.S_SOLDAT]


def hex_cmds(it):
    t = it['t']
    frame, base = {'B': (1, A.B_BEACH), 'D': (2, A.B_DIRT), 'M': (3, A.B_MOUNT)}[t]
    ctrl = {A.S_HEX: frame, base: it['n'] + 1, A.S_TEX: it.get('tex', 1), A.S_SMC: 1}
    if t == 'D':
        ctrl[A.S_ISLE] = it.get('v', 0) + 1
    if it.get('team') is not None:
        ctrl[A.S_SOLDAT] = TEAM[it['team']]
    inst = A.instance(A.S_HEX, ctrl)
    A.with_entry(inst, 'base', dy=-it.get('h', 0))
    b = [e for e in inst.display.values() if e['name'] == 'base'][0]['inst']
    for e in soldier_entries(b):
        # Socle.register: mc._x = Math.round(mc._x) (JS / Flash rounding: half up)
        e['matrix'] = dict(e['matrix'], tx=math.floor(e['matrix']['tx'] + 0.5), ty=math.floor(e['matrix']['ty'] + 0.5))
        if it.get('blink'):
            e['cx'] = dict(mult=[0.70, 0.70, 0.70, 1.0], add=[76, 76, 76, 0])
    return A.cmds_inst(inst)


def place(canvas, cmds, x, y, post=None):
    """draws commands at (x, y) Flash px on the page canvas (x4)"""
    M = dict(R.IDENT, tx=x, ty=y)
    moved = []
    rd = R.Renderer(A.G, K)
    layer = np.zeros_like(canvas)
    rd.draw([shift(c, M) for c in cmds], layer, (0, 0))
    if post:
        layer = post(layer)
    canvas *= (1 - layer[..., 3:4])
    canvas += layer


def shift(cmd, M):
    if cmd[0] == 'shape':
        return ('shape', cmd[1], R.mat_mul(M, cmd[2]), cmd[3])
    if cmd[0] == 'leaf':
        return ('leaf', cmd[1], cmd[2], R.mat_mul(M, cmd[3]), cmd[4])
    if cmd[0] == 'layer':
        return ('layer', [shift(c, M) for c in cmd[1]], cmd[2], cmd[3])
    if cmd[0] == 'mask':
        return ('mask', dict(mask=[shift(c, M) for c in cmd[1]['mask']], items=[shift(c, M) for c in cmd[1]['items']]))
    raise ValueError(cmd[0])


def anim_cmds(it):
    a, f = it['a'], it.get('f', 1)
    M = R.IDENT
    if 'xs' in it or 'r' in it:
        r = math.radians(it.get('r', 0))
        sx = it.get('xs', 100) / 100.0
        M = dict(a=math.cos(r) * sx, b=math.sin(r) * sx, c=-math.sin(r), d=math.cos(r), tx=0.0, ty=0.0)
    if a.startswith('dance'):
        return A.cmds_of(A.S_SOLDAT, {A.S_SOLDAT: int(a[-1]) + 1, A.S_SMC: 2, A.S_DANCE: f}, M)
    if a == 'sold':
        team, smc = (f - 1) % 2, 4 if f >= 5 else 1
        cx = R.NOCX if f < 3 or f > 4 else dict(mult=[0.7, 0.7, 0.7, 1.0], add=[76, 76, 76, 0])
        inst = A.instance(A.S_SOLDAT, {A.S_SOLDAT: team + 1, A.S_SMC: smc})
        return A.cmds_inst(inst, M, cx)
    sid = {'ray': A.S_RAY, 'onde': A.S_ONDE, 'star': A.S_STAR, 'drip': A.S_DRIP, 'shade': A.S_SHADE}[a]
    return A.cmds_of(sid, {sid: f}, M)


def castle_cmds(it):
    inst = A.instance(A.S_CASTLE, {A.S_CASTLE: 1, A.B_DIRT: it['frame'], A.S_ISLE: 2, A.S_TEX: it['tex'],
                                   A.S_SOLDAT: TEAM[it['team']], A.S_SMC: 1})
    return A.cmds_inst(inst)


# ---------------------------------------------------------------- texts (FFDec): inter and castle counters
def ffdec_sprite(tag, texts, sid):
    im = A.ffdec_render(tag, texts, sid)
    return im


def text_layer(sid, texts_on, texts_off, tag):
    """the pixels a text adds to a sprite (FFDec render with the text minus the one without), and the FFDec origin
    found by matching the render without text with swfrender's"""
    on = np.asarray(ffdec_sprite(tag + 'on', texts_on, sid), dtype=np.float32) / 255
    off = np.asarray(ffdec_sprite(tag + 'off', texts_off, sid), dtype=np.float32) / 255
    return on, off


def ffdec_origin(sid, ffdec_im):
    """Flash coordinates of the pixel (0, 0) of an FFDec render: the top left of the drawn pixels matched with the
    same sprite (every timeline on frame 1) rendered by swfrender"""
    imgs, reg = A.render([A.cmds_of(sid)], pad=1)
    bs = imgs[0].split()[3].point(lambda v: 255 if v > 128 else 0).getbbox()
    bf = ffdec_im.split()[3].point(lambda v: 255 if v > 128 else 0).getbbox()
    return (bs[0] - reg[0] - bf[0]) / K, (bs[1] - reg[1] - bf[1]) / K


Wd = 300 * K
for pi, page in enumerate(pages):
    canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
    texts = []
    for it in page:
        k = it['k']
        if k == 'hex':
            cmds = hex_cmds(it)
            post = A.HOVER if it.get('bright') else None
            place(canvas, cmds, it['x'], it['y'], post)
            if it.get('bright'):
                place(canvas, A.cmds_of(A.S_SEL), it['x'], it['y'] - it.get('h', 0), A.HOVER)
        elif k == 'castle':
            place(canvas, castle_cmds(it), it['x'], it['y'])
            if it.get('text') is not None:
                texts.append(('castle', it))
        elif k == 'inter':
            place(canvas, A.cmds_of(A.S_INTER), it['x'], it['y'])
            texts.append(('inter', it))
        else:
            place(canvas, anim_cmds(it), it['x'], it['y'])
    im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').resize((Wd, Wd), Image.LANCZOS).convert('RGBA')
    page_im = Image.new('RGBA', (Wd, Wd), BG + (255,))
    page_im.alpha_composite(im)
    for kind, it in texts:
        # the field alone: FFDec renders of the sprite with and without the text, differing only where the text is;
        # the text pixels are pasted at the place of the sprite (its FFDec origin: the top left of its bounds)
        if kind == 'inter':
            sid, on, off = A.S_INTER, {49: it['a'], 50: it['b']}, {49: '', 50: ''}
        else:
            sid, on, off = A.S_CASTLE, {37: it['text']}, {37: ''}
        a = A.ffdec_render('t%d_%s_on' % (pi, it['x']), on, sid)
        b = A.ffdec_render('t%d_%s_off' % (pi, it['x']), off, sid)
        ox, oy = ffdec_origin(sid, b)
        A_ = np.asarray(a, dtype=np.int16)
        B_ = np.asarray(b, dtype=np.int16)
        diff = np.abs(A_ - B_).max(axis=2) > 0
        x0, y0 = int(round((it['x'] + ox) * K)), int(round((it['y'] + oy) * K))
        P = np.array(page_im)
        src = np.asarray(a)
        # (clipped to the page)
        sx0, sy0 = max(0, -x0), max(0, -y0)
        dx0, dy0 = max(0, x0), max(0, y0)
        w = min(src.shape[1] - sx0, P.shape[1] - dx0)
        h = min(src.shape[0] - sy0, P.shape[0] - dy0)
        src = src[sy0:sy0 + h, sx0:sx0 + w]
        m = diff[sy0:sy0 + h, sx0:sx0 + w]
        sub = P[dy0:dy0 + h, dx0:dx0 + w]
        # (the text over the sprite's own pixels: FFDec's pixel composited over the page there)
        al = src[..., 3:4].astype(np.float32) / 255
        mix = (src[..., :3] * al + sub[..., :3] * (1 - al)).astype(np.uint8)
        sub[..., :3] = np.where(m[..., None], mix, sub[..., :3])
        P[dy0:dy0 + h, dx0:dx0 + w] = sub
        page_im = Image.fromarray(P)
    page_im.convert('RGB').save(os.path.join(OUT, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
