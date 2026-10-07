"""The comparison pages of Game.debugShow drawn from the SWF (swfrender): $KKP_WORK/toymaniak/check/ref<page>.png, to
compare with the game's screenshots (tpage.mjs -> run<page>.png) with tools/cmp_pages.py. The clips are placed as
debugShow places them; the buttons of the toys ("but", alpha 0 by code) and the counter of the panels are not drawn;
the shapes that mix vector and bitmap fills are rendered by rsvg-convert like in toymaniak_assets.py (bitmaps smoothed).
usage: python3 ref.py"""
import os, sys, math, re, io, subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'toymaniak', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z
RD = R.Renderer(G, 2)
for cid in (44, 53, 56, 59):
    w, h = G.shape_image(cid).size
    svg = open(W + 'svg_gfx/%d.svg' % cid).read()
    svg = re.sub(r'height="[^"]*px" width="[^"]*px"', 'height="%gpx" width="%gpx"' % (h / Z, w / Z), svg, count=1)
    r = subprocess.run(['rsvg-convert', '-z', str(Z)], input=svg.encode(), capture_output=True, check=True)
    G._shape_cache[cid] = Image.open(io.BytesIO(r.stdout)).convert('RGBA')
# the toys' bitmaps: FFDec draws bitmap fills unsmoothed at zoom 4, Flash smoothed them (rsvg too)
for cid in (4, 7, 10, 13, 16, 30, 33):
    w, h = G.shape_image(cid).size
    svg = open(W + 'svg_gfx/%d.svg' % cid).read()
    svg = re.sub(r'height="[^"]*px" width="[^"]*px"', 'height="%gpx" width="%gpx"' % (h / Z, w / Z), svg, count=1)
    r = subprocess.run(['rsvg-convert', '-z', str(Z)], input=svg.encode(), capture_output=True, check=True)
    G._shape_cache[cid] = Image.open(io.BytesIO(r.stdout)).convert('RGBA')


def M(tx=0.0, ty=0.0):
    return dict(a=1.0, b=0.0, c=0.0, d=1.0, tx=tx, ty=ty)


def page(items):
    cmds = []
    for sid, frame, x, y, ctrl, hide in items:
        i = R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))
        i.goto_and_stop(frame)
        RD.collect(i, M(x, y), R.NOCX, set(hide), cmds)
    can = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
    RD.draw(cmds, can, (0, 0))
    im = Image.fromarray(np.clip(can * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
    out = Image.new('RGBA', im.size, (0, 0, 0, 255))
    out.alpha_composite(im)
    return out.resize((600, 600), Image.LANCZOS).convert('RGB')


D = os.path.join(W, 'check')
os.makedirs(D, exist_ok=True)
p0 = [(76, 1, 0, 0, None, ())]
for k in range(11):
    p0.append((35, k + 1, 30 + 48 * (k % 6), 55 if k < 6 else 115, None, ('but',)))
for k, (sf, tf) in enumerate([(2, 1), (5, 2), (9, 3), (16, 8), (19, 0), (22, 0)]):
    p0.append((41, sf, 27 + 49 * k, 165, {'toy': tf} if tf else None, ('but',)))
for k in range(10):
    p0.append((68, k + 1, 15 + 28 * k, 215, None, ()))
    p0.append((72, k + 1, 15 + 28 * k, 245, None, ()))
page(p0).save(os.path.join(D, 'ref0.png'))
p1 = [(76, 1, 0, 0, None, ())]
for y, t0, t1, cy, tx, tf in ((80, -303, -305, -32.5, 150, 2), (200, -307, -301, -15, 38, 7)):
    p1.append((74, 1, 300, y, None, ('field',)))
    p1.append((35, tf, tx, y, None, ('but',)))
    # railFront: t0 / t1 at their frames 1 / 2 and moved, the cruncher moved: the matrices of the code
    i = R.Instance(G, 57, ctrl={'t0': 1, 't1': 2, '__noactions__': True})
    i.display[3] = dict(i.display[3], matrix=M(t0, i.display[3]['matrix']['ty']))
    i.display[5] = dict(i.display[5], matrix=M(t1, i.display[5]['matrix']['ty']))
    i.display[8] = dict(i.display[8], matrix=M(i.display[8]['matrix']['tx'], cy))
    p1.append(('inst', i, 300, y))
cmds = []
for it in p1:
    if it[0] == 'inst':
        RD.collect(it[1], M(it[2], it[3]), R.NOCX, set(), cmds)
    else:
        sid, frame, x, y, ctrl, hide = it
        ii = R.Instance(G, sid, ctrl=dict(ctrl or {}, __noactions__=True))
        ii.goto_and_stop(frame)
        RD.collect(ii, M(x, y), R.NOCX, set(hide), cmds)
can = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)
RD.draw(cmds, can, (0, 0))
im = Image.fromarray(np.clip(can * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
out = Image.new('RGBA', im.size, (0, 0, 0, 255))
out.alpha_composite(im)
out.resize((600, 600), Image.LANCZOS).convert('RGB').save(os.path.join(D, 'ref1.png'))
print('ref0.png ref1.png ->', D)
