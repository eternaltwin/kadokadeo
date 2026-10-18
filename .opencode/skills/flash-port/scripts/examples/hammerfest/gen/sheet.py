"""Levels of hfgen.js (JSON lines, run.cjs --wells) -> a sheet: one row per depth, one column per well (seed).
usage: python3 sheet.py <levels.jsonl> <out.png> [--cell 7] [--rows 0-49] [--nodark]
The darkness of each level is drawn like the game: a veil over the level, a light around Igor."""
import sys, json, argparse
from PIL import Image, ImageDraw, ImageFont

W = H = 18
FIELD = {-1: (235, 235, 235), -2: (25, 25, 25), -3: (70, 140, 255), -4: (70, 220, 70), -5: (255, 70, 70),
         -6: (0, 230, 230), -10: (255, 160, 0), -11: (200, 80, 255)}
# id: letter, colour (the kinds of Data.hx)
BAD = {0: ('P', (230, 40, 40)), 1: ('C', (190, 0, 60)), 2: ('B', (240, 220, 40)), 4: ('N', (240, 170, 0)),
       5: ('A', (250, 150, 60)), 6: ('a', (250, 180, 110)), 7: ('*', (160, 220, 60)), 8: ('O', (40, 40, 40)),
       9: ('o', (255, 140, 0)), 10: ('F', (255, 60, 120)), 11: ('L', (250, 250, 80)), 12: ('~', (120, 220, 200)),
       14: ('W', (180, 80, 200)), 16: ('X', (190, 190, 190)), 17: ('K', (240, 200, 200)), 18: ('k', (120, 160, 40)),
       19: ('K', (255, 230, 230)), 20: ('R', (200, 40, 160))}
WALKERS = {0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 14, 17, 18, 19, 20}

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('out')
ap.add_argument('--cell', type=int, default=7)
ap.add_argument('--rows', default=None)
ap.add_argument('--nodark', action='store_true')
a = ap.parse_args()
C = a.cell
lv = [json.loads(l) for l in open(a.src) if l.strip()]
if a.rows:
    r0, r1 = [int(v) for v in a.rows.split('-')]
    lv = [l for l in lv if r0 <= l['d'] <= r1]
seeds = sorted(set(l['s'] for l in lv))
depths = sorted(set(l['d'] for l in lv))
by = {(l['s'], l['d']): l for l in lv}

def font(sz, bold=True):
    for p in ('/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
              '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 'C:/Windows/Fonts/arialbd.ttf'):
        try:
            return ImageFont.truetype(p, sz)
        except Exception:
            pass
    return ImageFont.load_default()

F = font(max(8, C + 2)); FS = font(max(7, C), False); FB = font(C + 1)
GUT = 46            # left gutter: the depth
LAB = C + 6         # label over each tile
TW, TH = W * C + 6, H * C + LAB + 4
im = Image.new('RGB', (GUT + len(seeds) * TW, 16 + len(depths) * TH), (18, 18, 24))
d = ImageDraw.Draw(im)
for j, s in enumerate(seeds):
    d.text((GUT + j * TW + 4, 2), 'puits %d' % s, fill=(200, 200, 210), font=F)

def draw_level(l, ox, oy):
    m = l['map']
    tile = Image.new('RGBA', (W * C, H * C), (52, 42, 56, 255))
    t = ImageDraw.Draw(tile)
    for x in range(W):
        for y in range(H):
            v = m[x][y]
            r = (x * C, y * C, x * C + C - 1, y * C + C - 1)
            if v > 0:
                t.rectangle(r, fill=(150, 100, 60) if v == 1 else (112, 74, 46))
                if v == 1:
                    t.rectangle((r[0], r[1], r[2], r[1] + max(1, C // 4)), fill=(205, 155, 95))
            elif v < 0:
                c = FIELD.get(v, (255, 0, 255))
                horiz = (x > 0 and m[x - 1][y] == v) or (x < W - 1 and m[x + 1][y] == v)
                q = C // 3
                t.rectangle((r[0], r[1] + q, r[2], r[3] - q) if horiz else (r[0] + q, r[1], r[2] - q, r[3]), fill=c)
    for p in l.get('oe', []):
        t.rectangle((p['x'] * C, p['y'] * C, p['x'] * C + C - 1, p['y'] * C + C - 1), outline=(255, 255, 255))
    for s in l['sp']:
        t.text((s['x'] * C + 1, s['y'] * C - 2), 'S', fill=(255, 230, 0), font=FS)
    for s in l['sc']:
        t.text((s['x'] * C + 1, s['y'] * C - 2), '$', fill=(120, 255, 120), font=FS)
    for b in l['bads']:
        x, y = b['x'] * C, b['y'] * C
        if b['id'] == 13:  # spikes
            up = b['y'] > 0 and m[b['x']][b['y'] - 1] > 0
            dn = b['y'] < H - 1 and m[b['x']][b['y'] + 1] > 0
            if dn or not up:
                t.polygon([(x, y + C - 1), (x + C // 2, y + 1), (x + C - 1, y + C - 1)], fill=(255, 40, 40))
            else:
                t.polygon([(x, y), (x + C // 2, y + C - 2), (x + C - 1, y)], fill=(255, 40, 40))
            continue
        ch, c = BAD.get(b['id'], ('?', (255, 0, 255)))
        t.ellipse((x - 1, y - 1, x + C, y + C), fill=c, outline=(0, 0, 0))
        t.text((x + 1, y - 2), ch, fill=(0, 0, 0) if sum(c) > 330 else (255, 255, 255), font=FB)
    x, y = l['px'] * C, l['py'] * C
    t.rectangle((x, y, x + C - 1, y + C - 1), fill=(255, 255, 255))
    t.text((x + 1, y - 2), '@', fill=(0, 0, 0), font=FB)
    # entry columns: a tick over the columns where Igor can come in
    for x in range(W):
        if x < len(l['en']) and l['en'][x]:
            t.rectangle((x * C + 1, 0, x * C + C - 2, 0), fill=(120, 255, 120))
    dark = 0 if a.nodark else l['dark']
    if dark > 0:
        veil = Image.new('L', tile.size, int(255 * 0.92 * dark / 100))
        vd = ImageDraw.Draw(veil)
        cx, cy = l['px'] * C + C / 2, l['py'] * C + C / 2
        for k, rad in enumerate((4.2, 3.6, 3.0)):
            vd.ellipse((cx - rad * C, cy - rad * C, cx + rad * C, cy + rad * C), fill=int(255 * 0.92 * dark / 100 * (0.55 - 0.25 * k)))
        black = Image.new('RGBA', tile.size, (0, 0, 0, 255))
        black.putalpha(veil)
        tile = Image.alpha_composite(tile, black)
    im.paste(tile, (ox, oy))
    n = sum(1 for b in l['bads'] if b['id'] in WALKERS or b['id'] == 12)
    d.text((ox, oy - LAB + 1), 'w%.1f n%d %s%s' % (l['budget'], n, l['concept'][:9], ' d%d' % l['dark'] if l['dark'] else ''),
           fill=(200, 200, 210), font=FS)

for i, dp in enumerate(depths):
    oy = 16 + i * TH + LAB
    d.text((4, oy + H * C // 2 - 6), 'n%d' % dp, fill=(255, 255, 255), font=F)
    for j, s in enumerate(seeds):
        l = by.get((s, dp))
        if l:
            draw_level(l, GUT + j * TW + 3, oy)
im.save(a.out)
print(a.out, im.size, len(lv), 'levels')
