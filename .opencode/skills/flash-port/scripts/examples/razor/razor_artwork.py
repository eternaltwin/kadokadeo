"""Start screen of Razor (public/assets/img/gfx/artwork/razor.jpg, 600 x 600): a moment of a combo drawn by the port
(the pictures of the SWF) chosen among the candidates of rart.mjs ($KKP_WORK/razor/art/<name>.png): there is no old
thumbnail of the game; the archive's screenshot sc/sc3.jpg shows the same moment ("ARCHI-GORE!").
usage: razor_artwork.py <candidate name, e.g. b17> <out jpg>"""
import os, sys
from PIL import Image

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'razor', '')
im = Image.open(W + 'art/%s.png' % sys.argv[1]).convert('RGB')
assert im.size == (600, 600), im.size
im.save(sys.argv[2], quality=90, optimize=True)
print(sys.argv[2], os.path.getsize(sys.argv[2]))
