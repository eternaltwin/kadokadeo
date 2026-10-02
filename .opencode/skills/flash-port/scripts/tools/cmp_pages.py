"""Compares the pages drawn by the game (run<i>.png, screenshots of a debug page) with the same pages rendered from
the SWF (ref<i>.png, swfrender): writes cmp<i>.png = game | SWF | difference x4, prints how many pixels differ.
Anti-aliasing gives a thin outline in the difference; a whole sprite lit up is a real difference (offset, frame,
colour). Random effects (sparkles, particles) differ by design.
usage: cmp_pages.py <dir> [threshold 0-255, default 48]"""
import sys, os, glob, re
import numpy as np
from PIL import Image

D = sys.argv[1]
TH = int(sys.argv[2]) if len(sys.argv) > 2 else 48
runs = sorted(glob.glob(os.path.join(D, 'run*.png')), key=lambda p: int(re.findall(r'(\d+)\.png$', p)[0]))
for run in runs:
    i = re.findall(r'(\d+)\.png$', run)[0]
    ref = os.path.join(D, 'ref%s.png' % i)
    if not os.path.exists(ref):
        print('run%s: no ref%s.png' % (i, i))
        continue
    a = Image.open(run).convert('RGB')
    b = Image.open(ref).convert('RGB')
    if b.size != a.size:
        b = b.resize(a.size)
    A, B = np.asarray(a).astype(np.int16), np.asarray(b).astype(np.int16)
    d = np.abs(A - B)
    over = (d.max(axis=2) > TH)
    out = Image.new('RGB', (a.width * 3 + 10, a.height), (40, 40, 40))
    out.paste(a, (0, 0))
    out.paste(b, (a.width + 5, 0))
    out.paste(Image.fromarray(np.clip(d * 4, 0, 255).astype(np.uint8)), (2 * a.width + 10, 0))
    out.save(os.path.join(D, 'cmp%s.png' % i))
    print('page %s: %.2f %% of the pixels differ by more than %d (mean difference %.2f) -> cmp%s.png'
          % (i, over.mean() * 100, TH, d.mean(), i))
