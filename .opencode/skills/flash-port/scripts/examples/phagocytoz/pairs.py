"""Side by side pages of rframes.mjs / pframes.mjs screenshots: per frame, the original (Ruffle) | the port, at half
size, optionally a crop at full size.
usage: pairs.py <dir> <r prefix> <p prefix> <frames comma separated> <out.png> [crop x,y,w,h (canvas pixels)]"""
import sys
from PIL import Image, ImageDraw

d, rp, pp, frames, out = sys.argv[1:6]
crop = [int(v) for v in sys.argv[6].split(',')] if len(sys.argv) > 6 else None
frames = frames.split(',')
cells = []
for f in frames:
    r = Image.open('%s/%s_%s.png' % (d, rp, f)).convert('RGB')
    p = Image.open('%s/%s_%s.png' % (d, pp, f)).convert('RGB')
    if crop:
        x, y, w, h = crop
        r = r.crop((x, y, x + w, y + h))
        p = p.crop((x, y, x + w, y + h))
    else:
        r = r.resize((300, 300), Image.LANCZOS)
        p = p.resize((300, 300), Image.LANCZOS)
    cells.append((f, r, p))
w, h = cells[0][1].size
cols = 2 if not crop or w < 400 else 1
rows = (len(cells) + cols - 1) // cols
o = Image.new('RGB', (cols * (2 * w + 30), rows * (h + 22)), (40, 40, 40))
dr = ImageDraw.Draw(o)
for i, (f, r, p) in enumerate(cells):
    x0 = (i % cols) * (2 * w + 30)
    y0 = (i // cols) * (h + 22)
    dr.text((x0 + 4, y0 + 4), 'frame %s: original | port' % f, fill=(255, 255, 255))
    o.paste(r, (x0, y0 + 20))
    o.paste(p, (x0 + w + 4, y0 + 20))
o.save(out)
