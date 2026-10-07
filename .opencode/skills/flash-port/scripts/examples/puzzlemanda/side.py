"""Side by side pictures of pruf.mjs: original (Ruffle) | port, one row per moment.
usage: side.py <out.png> <name> [name...]   (names of $KKP_WORK/puzzlemanda/cmp/<ref|port>_<name>.png)   env: SCALE (0.5)"""
import os, sys
from PIL import Image, ImageDraw
D = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'puzzlemanda', 'cmp')
sc = float(os.environ.get('SCALE', '0.5'))
rows = []
for n in sys.argv[2:]:
    ims = []
    for m in ('ref', 'port'):
        p = os.path.join(D, '%s_%s.png' % (m, n))
        ims.append(Image.open(p).convert('RGB') if os.path.exists(p) else Image.new('RGB', (600, 600), (40, 40, 40)))
    rows.append((n, ims))
w, h = int(600 * sc), int(600 * sc)
out = Image.new('RGB', (2 * w + 30, len(rows) * (h + 18)), (233, 249, 255))
dr = ImageDraw.Draw(out)
for i, (n, ims) in enumerate(rows):
    y = i * (h + 18)
    dr.text((4, y + 2), '%s   original (Ruffle)  |  port' % n, fill=(0, 0, 0))
    for j, im in enumerate(ims):
        out.paste(im.resize((w, h), Image.LANCZOS), (j * (w + 30), y + 16))
out.save(sys.argv[1])
print(out.size)
