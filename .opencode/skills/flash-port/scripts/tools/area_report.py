import os, sys, glob, hashlib
from PIL import Image

src = sys.argv[1]
groups = {}
seen = set()
for f in glob.glob(os.path.join(src, '**', '*.png'), recursive=True):
    rel = os.path.relpath(f, src).replace(os.sep, '/')
    g = rel.rsplit('/', 1)[0] if '/' in rel else rel[:-4]
    im = Image.open(f)
    bb = im.split()[3].getbbox()
    if bb is None:
        continue
    c = im.crop(bb)
    h = hashlib.sha1(c.tobytes()).hexdigest()
    a = (bb[2] - bb[0]) * (bb[3] - bb[1])
    if h in seen:
        a = 0
    seen.add(h)
    groups[g] = groups.get(g, 0) + a
tot = sum(groups.values())
for g, a in sorted(groups.items(), key=lambda t: -t[1])[:int(sys.argv[2]) if len(sys.argv) > 2 else 25]:
    print('%-18s %6.0fk  %4.1f%%' % (g, a / 1000, 100 * a / tot))
print('total trimmed %.2f Mpx (one 2048 sheet = 4.19 Mpx)' % (tot / 1e6))
