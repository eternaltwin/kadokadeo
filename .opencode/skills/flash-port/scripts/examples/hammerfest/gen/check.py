"""The rules of the design of the levels checked on the levels of hfgen.js: python3 check.py <levels.jsonl> [-v]
Hard rules (the level is wrong) and soft ones (to watch). Prints the violations by rule and the depths they happen at."""
import sys, json, collections, math
W = H = 18
WALKERS = {0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 17, 18, 19, 20}
NAMES = {0: 'pomme', 1: 'cerise', 2: 'banane', 4: 'ananas', 5: 'abricot', 7: 'poire', 8: 'bombino', 9: 'orange', 10: 'fraise',
         11: 'citron', 12: 'bondissante', 13: 'pics', 14: 'blob', 16: 'scie', 17: 'litchi', 18: 'kiwi', 20: 'framboise'}
src = sys.argv[1]
verbose = '-v' in sys.argv
lv = [json.loads(l) for l in open(src) if l.strip()]
viol = collections.defaultdict(list)  # rule -> [(seed, depth, detail)]

def g(m, x, y):
    if x < 0 or x >= W:
        return 1
    if y < 0 or y >= H:
        return 0
    return m[x][y]

def seg_of(m, x, y):
    """the platform (standing cells) holding the standing cell (x, y)"""
    x0 = x
    while x0 - 1 >= 0 and m[x0 - 1][y] <= 0 and g(m, x0 - 1, y + 1) > 0:
        x0 -= 1
    x1 = x
    while x1 + 1 < W and m[x1 + 1][y] <= 0 and g(m, x1 + 1, y + 1) > 0:
        x1 += 1
    return x0, x1

for l in lv:
    s, dp, m = l['s'], l['d'], l['map']
    key = (s, dp)
    bads = l['bads']
    has = lambda v: any(m[x][y] == v for x in range(W) for y in range(H))
    black, blue, red = has(-2), has(-3), has(-5)
    # 1. entry columns (Igor falls in from the top)
    en = sum(1 for v in l['en'] if v)
    if en < 3:
        viol['entry<3 (hard)'].append((s, dp, en))
    elif en < 6:
        viol['entry<6 (soft)'].append((s, dp, en))
    # 2. headroom: a bad (and a reached standing cell) has the case over it free
    reach = l.get('reach')
    for b in bads:
        if b['id'] in WALKERS and g(m, b['x'], b['y'] - 1) > 0:
            viol['headroom bad (hard)'].append((s, dp, NAMES.get(b['id'], b['id'])))
    if reach:
        n = sum(1 for x in range(W) for y in range(1, H) if reach[x][y] and m[x][y - 1] > 0)
        if n:
            viol['headroom reached cell (hard)'].append((s, dp, n))
        # 3. walking bads on a reached platform (or next to one: bombed from a neighbour)
        for b in bads:
            if b['id'] not in WALKERS:
                continue
            x0, x1 = seg_of(m, b['x'], b['y'])
            if not any(reach[x][b['y']] for x in range(x0, x1 + 1)):
                near = any(reach[x][y] for x in range(x0 - 2, x1 + 3) for y in range(b['y'] - 3, b['y'] + 2) if 0 <= x < W and 0 <= y < H)
                viol['bad unreached' + (' near (soft)' if near else ' (hard)')].append((s, dp, NAMES.get(b['id'])))
    # 4. lemons: in the middle band and shut in only with a black laser
    for b in bads:
        if b['id'] != 11:
            continue
        y = b['y']
        if 5 <= y <= H - 6:
            x0, x1 = seg_of(m, b['x'], y)
            walls = g(m, x0 - 1, y) > 0 and g(m, x1 + 1, y) > 0
            head = 0
            yy = y - 1
            cx = (x0 + x1) >> 1
            while yy >= 0 and m[cx][yy] <= 0:
                head += 1; yy -= 1
            if (walls or head <= 3) and not black:
                viol['citron milieu cloisonne sans noir (hard)'].append((s, dp, (b['x'], y)))
            elif not black:
                viol['citron milieu (soft)'].append((s, dp, (b['x'], y)))
    # 5. groups: bombinos, litchis, apricots; counts
    def pairs(id_, dist):
        pts = [(b['x'], b['y']) for b in bads if b['id'] == id_]
        return sum(1 for i in range(len(pts)) for j in range(i + 1, len(pts)) if abs(pts[i][0] - pts[j][0]) + abs(pts[i][1] - pts[j][1]) <= dist)
    cnt = collections.Counter(b['id'] for b in bads)
    if pairs(8, 4):
        viol['bombinos groupes <=4 (hard)'].append((s, dp, pairs(8, 4)))
    if cnt[8] > 3:
        viol['bombinos >3 (hard)'].append((s, dp, cnt[8]))
    if pairs(17, 3):
        viol['litchis groupes <=3 (soft)'].append((s, dp, pairs(17, 3)))
    if pairs(5, 3):
        viol['abricots groupes <=3 (soft)'].append((s, dp, pairs(5, 3)))
    if cnt[5] > 4:
        viol['abricots >4 (hard)'].append((s, dp, cnt[5]))
    if cnt[10] > 6:
        viol['fraises >6 (hard)'].append((s, dp, cnt[10]))
    # 6. pockets: a black or blue laser
    if l.get('pockets', 0) > 0 and not (black or blue):
        viol['poche sans laser noir/bleu (hard)'].append((s, dp, l['pockets']))
    # 7. a way down: the bottom row has a hole or the columns are open
    if all(m[x][H - 1] > 0 for x in range(W)) and not l.get('oe'):
        viol['pas de trou au bas (hard)'].append((s, dp, 0))
    # 8. darkness
    if dp >= 50 and l['dark'] < 100:
        viol['noirceur <100 a 50+ (hard)'].append((s, dp, l['dark']))

# 9. weight growing with the depth
byd = collections.defaultdict(list)
for l in lv:
    byd[l['d']].append(l['budget'])
mean = {d: sum(v) / len(v) for d, v in byd.items()}
ds = sorted(mean)
for a, b in zip(ds, ds[1:]):
    if mean[b] < mean[a] * 0.9:
        viol['poids moyen en baisse >10% (soft)'].append((0, b, '%.1f -> %.1f' % (mean[a], mean[b])))

print('%d levels, %d wells, depths %d..%d' % (len(lv), len(set(l['s'] for l in lv)), ds[0], ds[-1]))
hard = 0
for rule in sorted(viol, key=lambda r: ('hard' not in r, r)):
    v = viol[rule]
    if 'hard' in rule:
        hard += len(v)
    depths = collections.Counter(x[1] for x in v)
    print('%-45s %4d   depths: %s' % (rule, len(v), ' '.join('%d:%d' % kv for kv in sorted(depths.items())[:24])))
    if verbose:
        for x in v[:12]:
            print('     ', x)
print('HARD VIOLATIONS:', hard)
