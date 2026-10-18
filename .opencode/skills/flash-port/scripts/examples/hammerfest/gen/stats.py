"""Statistics of the levels of hfgen.js by depth: python3 stats.py <levels.jsonl> [fails.txt]"""
import sys, json, collections, statistics as st
W = H = 18
NAMES = {0: 'pomme', 1: 'cerise', 2: 'banane', 4: 'ananas', 5: 'abricot', 6: 'nainbricot', 7: 'poire', 8: 'bombino', 9: 'orange',
         10: 'fraise', 11: 'citron', 12: 'bondiss', 13: 'pics', 14: 'blob', 16: 'scie', 17: 'litchi', 18: 'kiwi', 20: 'framboise'}
WALK = {0, 1, 2, 4, 5, 7, 8, 9, 10, 11, 12, 14, 17, 18, 20}
lv = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
byd = collections.defaultdict(list)
for l in lv:
    byd[l['d']].append(l)

def platforms(m):
    n = 0
    for y in range(H):
        x = 0
        while x < W:
            if m[x][y] <= 0 and y + 1 < H and m[x][y + 1] > 0:
                while x < W and m[x][y] <= 0 and m[x][y + 1] > 0:
                    x += 1
                n += 1
            else:
                x += 1
    return n

def ground(m):
    return sum(1 for x in range(W) for y in range(H) if m[x][y] > 0) / (W * H)

print('%4s %6s %6s %5s %5s %5s %5s %5s %5s %5s  %s' % ('d', 'poids', 'sd', 'bads', 'plats', 'sol%', 'laser', 'tele', 'pics', 'dark', 'concepts / kinds'))
for d in sorted(byd):
    L = byd[d]
    w = [l['budget'] for l in L]
    nb = [sum(1 for b in l['bads'] if b['id'] in WALK) for l in L]
    pl = [platforms(l['map']) for l in L]
    gr = [ground(l['map']) for l in L]
    laser = sum(1 for l in L if any(-5 <= l['map'][x][y] <= -1 or l['map'][x][y] == -11 for x in range(W) for y in range(H)))
    tele = sum(1 for l in L if any(l['map'][x][y] == -6 for x in range(W) for y in range(H)))
    pics = sum(1 for l in L if any(b['id'] == 13 for b in l['bads']))
    con = collections.Counter(l['concept'] for l in L)
    kinds = collections.Counter(NAMES.get(b['id'], b['id']) for l in L for b in l['bads'] if b['id'] in WALK)
    print('%4d %6.1f %6.1f %5.1f %5.1f %5.0f %5d %5d %5d %5d  %s | %s' % (
        d, st.mean(w), st.pstdev(w), st.mean(nb), st.mean(pl), 100 * st.mean(gr), laser, tele, pics, L[0]['dark'],
        ' '.join('%s:%d' % kv for kv in con.most_common(4)), ' '.join('%s:%d' % kv for kv in kinds.most_common(6))))
# the failures of the levels drawn (LevelGen.fail: kind:reason=count per level), by reason, and the levels of fallback
agg = collections.Counter()
relaxed = []
for l in lv:
    for k in l.get('fails', []):
        key, n = k.rsplit('=', 1)
        agg[key.split(':')[-1]] += int(n)
        if key == 'relaxed':
            relaxed.append((l['s'], l['d'], int(n)))
print('\nfails by reason:', ' '.join('%s=%d' % kv for kv in agg.most_common(16)))
print('levels needing the relaxed tries: %d, fallback levels: %d' % (len(relaxed), sum(1 for l in lv if 'fallback' in l['kind'])),
      sorted(relaxed, key=lambda t: -t[2])[:12])
