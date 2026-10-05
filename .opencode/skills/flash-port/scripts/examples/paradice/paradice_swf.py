"""The SWF files of Paradice for swfrender (gfx.swf, part.swf, decor.swf: the graphics of the released temple.swf,
identical except one unused sprite). Used by paradice_assets.py and ref.py."""
import os, sys, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'paradice', '')   # SWF + FFDec exports

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)       # characters, gems, effects, interface
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)      # its bitmaps (portraits, panel) at their native resolution
Gq = R.SWF(W + 'part.swf', W + 'shp4_part', Z=4)    # ice particles, score bubble, ground line
Gd = R.SWF(W + 'decor.swf', W + 'shp1_decor', Z=1)  # background and window frame: bitmaps only
for X in (G, G1, Gq, Gd):
    X.flash_replace = True
for X, n in ((G, 'gfx'), (Gq, 'part'), (Gd, 'decor')):
    X.svg_dir = W + 'svg_' + n                       # shape layers (shape_layers: the balls drawn under an alpha)


def bitmap_shapes(swf):
    """ids of the shapes filled with a bitmap (FFDec SVG export: a pattern fill)"""
    return sorted(int(os.path.basename(f)[:-4]) for f in glob.glob(W + 'svg_%s/*.svg' % swf) if 'pattern' in open(f).read())
