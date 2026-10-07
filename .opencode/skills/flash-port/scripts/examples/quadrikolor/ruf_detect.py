"""Positions on a screenshot of the original in Ruffle (600 x 600, x2): the ship (centre of its black shadow, approximately) and the
balls (centre of the pixels of their colour, Const.COLORS), in game pixels. usage: ruf_detect.py <png> -> JSON"""
import sys, json
import numpy as np
from PIL import Image
COLORS = [0xDD0000, 0xEEAA00, 0xDDEE22, 0x33DD22, 0x22AA88, 0x4488EE, 0xAA55DD]
a = np.asarray(Image.open(sys.argv[1]).convert('RGB'), dtype=np.int32)
a[:30] = 128
out = {'balls': []}
from scipy.ndimage import uniform_filter
# (the black pupils of the balls are black too: the densest 40 x 40 px window of black)
blk = (a.sum(axis=2) < 25).astype(np.float32)
d = uniform_filter(blk, 40)
y, x = np.unravel_index(np.argmax(d), d.shape)
if d[y, x] > 0.05:
    out['ship'] = [float(x) / 2, float(y) / 2]
for i, c in enumerate(COLORS):
    col = np.array([c >> 16, (c >> 8) & 255, c & 255])
    m = (np.abs(a - col).sum(axis=2) < 45)
    ys, xs = np.nonzero(m)
    if len(xs) > 120:
        out['balls'].append([i, float(np.median(xs)) / 2, float(np.median(ys)) / 2, int(len(xs))])
print(json.dumps(out))
