"""Contact sheet of FFDec sprite exports: one row per sprite folder, frames side by side (scaled to fit)."""
import sys, os, glob, re
from PIL import Image, ImageDraw

out = sys.argv[1]
folders = sys.argv[2:]
MAXH = 90
MAXW = 1800
rows = []
for d in folders:
    fs = sorted(glob.glob(os.path.join(d, '*.png')), key=lambda f: int(re.sub(r'\D', '', os.path.basename(f)) or 0))
    ims = []
    for f in fs[:40]:
        im = Image.open(f).convert('RGBA')
        s = min(1.0, MAXH / max(1, im.height))
        if s < 1:
            im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
        ims.append(im)
    if ims:
        rows.append((os.path.basename(d) + ' (%d) %dx%d' % (len(fs), Image.open(fs[0]).width, Image.open(fs[0]).height), ims))
H = sum(max(i.height for i in ims) + 16 for _, ims in rows) + 4
sheet = Image.new('RGBA', (MAXW, H), (120, 120, 140, 255))
dr = ImageDraw.Draw(sheet)
y = 0
for name, ims in rows:
    dr.text((2, y + 1), name, fill=(255, 255, 0, 255))
    x = 0
    h = max(i.height for i in ims)
    for im in ims:
        if x + im.width > MAXW:
            break
        sheet.alpha_composite(im, (x, y + 14))
        x += im.width + 3
    y += h + 16
sheet.convert('RGB').save(out)
print(sheet.size)
