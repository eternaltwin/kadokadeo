import sys
import os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
which = sys.argv[1]
W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kslash', '')
G = R.SWF(W + '%s.swf' % which, W + 'shp4_%s' % which, Z=4)
def names_over(sid):
    sd = G.sprites[sid]
    seen = {}
    for f in range(1, sd.nframes + 1):
        inst = R.Instance(G, sid, ctrl={sid: f, '__noactions__': True})
        for d in sorted(inst.display):
            e = inst.display[d]
            key = (d, e['name'], e['inst'].sid if e['inst'] else ('shape', e['char']))
            seen.setdefault(key, []).append(f)
    return seen
def rng(fs):
    out = []; s = fs[0]; p = fs[0]
    for f in fs[1:]:
        if f != p + 1:
            out.append('%d-%d' % (s, p) if s != p else str(s)); s = f
        p = f
    out.append('%d-%d' % (s, p) if s != p else str(s))
    return ','.join(out)
for sid in sorted(G.exports) if len(sys.argv) < 3 else [int(x) for x in sys.argv[2:]]:
    sd = G.sprites.get(sid)
    if sd is None: continue
    print('== %d %s frames=%d labels=%s' % (sid, G.exports.get(sid, ''), sd.nframes, sorted(sd.labels.items(), key=lambda x: x[1])))
    for (d, n, c), fs in sorted(names_over(sid).items(), key=lambda kv: (kv[0][0], str(kv[0][1]), str(kv[0][2]))):
        sub = ''
        if isinstance(c, int):
            ssd = G.sprites[c]
            sub = 'sprite %d nf=%d labels=%s' % (c, ssd.nframes, ssd.labels if ssd.labels else '')
        else:
            sub = 'shape %d' % c[1]
        print('   d=%-3d %-10s %-40s frames %s' % (d, n or '', sub, rng(fs)))
