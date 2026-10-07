"""The SWF of Julianus for swfrender (gfx.swf, shapes of FFDec at zoom 4), with what it cannot draw added: the sprites
drawn with morph shapes (the bonus glows 46 / 60, pop, fxBonus) from FFDec's renders frame by frame (spr4_gfx/, see
rebuild_assets.sh). Used by julianus_assets.py and ref.py."""
import os, sys, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'julianus', '')
K = 2          # texture pixels per Flash pixel (the game is drawn x2)
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
Z = G.Z


def collect(inst, cx=R.NOCX):
    out = []
    R.Renderer(G, K).collect(inst, R.IDENT, cx, set(), out)
    return out


# ---------------------------------------------------------------- morph shapes: FFDec renders of their sprites
def ffdec_leaf(sid, folder, ref_frame):
    """the sprite drawn from FFDec's frames (spr4_gfx/<folder>/N.png, zoom 4), placed by matching its frame ref_frame
    (no morph shape on it) with the render of swfrender"""
    path = W + 'spr4_gfx/' + folder
    n = G.sprites[sid].nframes
    ff = np.asarray(Image.open(os.path.join(path, '%d.png' % ref_frame)).convert('RGBA'), dtype=np.float32)[..., 3] / 255
    cmds = collect(R.frame_states(G, sid, [ref_frame])[0])
    rd = R.Renderer(G, K)
    bb = rd.bounds(cmds)
    ox, oy = math.floor(bb[0]), math.floor(bb[1])
    Wz, Hz = int((math.ceil(bb[2]) - ox) * Z), int((math.ceil(bb[3]) - oy) * Z)
    canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
    rd.draw(cmds, canvas, (ox, oy))
    sw = canvas[..., 3]

    def bbox(a):
        ys, xs = np.nonzero(a > 0.5)
        return xs.min(), ys.min()

    fx, fy = bbox(ff)
    sx, sy = bbox(sw)
    # (FFDec's canvas is cut at the shapes' bounds, the render of swfrender has a margin: pad it)
    M = max(Wz, Hz)
    ffp = np.pad(ff, M)
    best = None
    for dy in range(-12, 13):
        for dx in range(-12, 13):
            px, py = fx - sx + dx, fy - sy + dy
            e = np.abs(ffp[M + py:M + py + Hz, M + px:M + px + Wz] - sw).sum()
            if best is None or e < best[0]:
                best = (e, px, py)
    e, px, py = best
    print('leaf %d: offset %d %d (from the bounds %+d %+d), error %.1f px' % (sid, px, py, px - fx + sx, py - fy + sy, e / Z / Z))
    G.add_leaf(sid, path, (ox - px / Z, oy - py / Z), n)


ffdec_leaf(46, 'DefineSprite_46', 20)
ffdec_leaf(60, 'DefineSprite_60', 20)
ffdec_leaf(95, 'DefineSprite_95_pop', 8)
ffdec_leaf(89, 'DefineSprite_89_fxBonus', 1)
