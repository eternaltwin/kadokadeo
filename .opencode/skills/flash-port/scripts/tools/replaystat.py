"""usage: replaystat.py <replay.txt>...   decode KadoKadeo replays (versions 1 to 3) and show the size of each section"""
import base64
import sys
import zlib


class R:
    def __init__(self, b):
        self.b, self.p = b, 0

    def byte(self):
        v = self.b[self.p]
        self.p += 1
        return v

    def var(self):
        r = s = 0
        while True:
            v = self.byte()
            r |= (v & 0x7F) << s
            if not v & 0x80:
                return r
            s += 7

    def zz(self):
        v = self.var()
        return (v >> 1) ^ -(v & 1)


def decode(text):
    raw = base64.b64decode(text.strip())
    try:
        data = zlib.decompress(raw)
    except zlib.error:
        data = raw
    r = R(data)
    assert data[:4] == b'KADO', data[:4]
    r.p = 4
    ver = r.byte()
    flags = r.byte()
    out = dict(version=ver, flags=flags, raw=len(raw), b64=len(text.strip()), bin=len(data), sections={})
    start = r.p
    keys = [r.var() for _ in range(r.var())] if flags & 1 else []
    buttons = [r.var() for _ in range(r.var())] if flags & 8 and ver >= 2 else []
    out['keys'], out['buttons'] = keys, buttons
    out['sections']['header'] = r.p - start
    inputs, events, mouse, clicks = [], [], [], []
    def frames3():
        n = r.var()
        fs, f = [], 0
        for _ in range(n):
            f += r.var()
            fs.append(f)
        return fs

    def moves3(fs):
        vals, prev, pm = [], 0, 0
        for i in range(len(fs)):
            cons = i > 0 and fs[i] - fs[i - 1] == 1
            m = r.zz() + (pm if cons else 0)
            pm = m if cons else 0
            prev += m
            vals.append(prev)
        return vals

    if flags & 1:
        s = r.p
        if ver >= 3:
            fs = frames3()
            for f in fs:
                v = r.var()
                inputs.append((f, v >> 1 if flags & 16 else keys[v >> 1], v & 1))
        else:
            f = 0
            for _ in range(r.var()):
                f += r.var()
                for _ in range(r.var()):
                    v = r.var()
                    inputs.append((f, v >> 1, v & 1))
        out['sections']['inputs'] = r.p - s
    if flags & 2:
        s = r.p
        f = 0
        for _ in range(r.var()):
            f += r.var()
            for _ in range(r.var()):
                enc = r.byte()
                if enc == 0:
                    events.append((f, r.byte()))
                else:
                    n = r.var()
                    events.append((f, data[r.p:r.p + n]))
                    r.p += n
        out['sections']['events'] = r.p - s
    if flags & 4 and ver >= 2:
        s = r.p
        if ver >= 3:
            fs = frames3()
            xs = moves3(fs)
            ys = moves3(fs)
            mouse = list(zip(fs, xs, ys))
        else:
            f = 0
            for _ in range(r.var()):
                f += r.var()
                mouse.append((f, r.var(), r.var()))
        out['sections']['mouse'] = r.p - s
    if flags & 8 and ver >= 2:
        s = r.p
        if ver >= 3:
            for f in frames3():
                v = r.var()
                clicks.append((f, v >> 1 if flags & 32 else buttons[v >> 1], v & 1))
        else:
            f = 0
            for _ in range(r.var()):
                f += r.var()
                for _ in range(r.var()):
                    v = r.var()
                    clicks.append((f, v >> 1, v & 1))
        out['sections']['clicks'] = r.p - s
    if data[r.p:r.p + 3] == b'LEN':
        r.p += 3
        out['frames'] = r.var()
    out['counts'] = dict(inputs=len(inputs), events=len(events), mouse=len(mouse), clicks=len(clicks))
    out['data'] = dict(inputs=inputs, events=events, mouse=mouse, clicks=clicks)
    return out


if __name__ == '__main__':
    for p in sys.argv[1:]:
        d = decode(open(p).read())
        print('%s v%d flags %d: base64 %d, deflated %d, binary %d, frames %s, keys %s, buttons %s' % (
            p, d['version'], d['flags'], d['b64'], d['raw'], d['bin'], d.get('frames'), d['keys'], d['buttons']))
        print('   sections %s  counts %s' % (d['sections'], d['counts']))


def encode_v3(d, frames_total):
    """version 3 writer, same bytes as ReplayManager.encodeBinaryData (d: result of decode())"""
    def var(o, v):
        while v >= 0x80:
            o.append((v & 0x7F) | 0x80)
            v >>= 7
        o.append(v)

    def zz(o, v):
        var(o, v << 1 if v >= 0 else ((-v) << 1) - 1)

    data, keys, buttons = d['data'], d['keys'], d['buttons']
    flags = d['flags'] & 15
    kidx = {k: i for i, k in reversed(list(enumerate(keys)))} if keys else {}
    bidx = {b: i for i, b in reversed(list(enumerate(buttons)))} if buttons else {}
    if any(k not in kidx for _, k, _ in data['inputs']):
        flags |= 16
    if any(b not in bidx for _, b, _ in data['clicks']):
        flags |= 32
    o = bytearray(b'KADO\x03')
    o.append(flags)
    if flags & 1:
        var(o, len(keys))
        for k in keys: var(o, k)
    if flags & 8:
        var(o, len(buttons))
        for b in buttons: var(o, b)

    def changes(items, table, codes):
        var(o, len(items))
        p = 0
        for it in items:
            var(o, it[0] - p); p = it[0]
        for it in items:
            var(o, ((it[1] if codes else table[it[1]]) << 1) | it[2])

    if flags & 1:
        changes(data['inputs'], kidx, flags & 16)
    if flags & 2:
        ev = {}
        for f, e in data['events']:
            ev.setdefault(f, []).append(e)
        var(o, len(ev)); p = 0
        for f in sorted(ev):
            var(o, f - p); p = f
            var(o, len(ev[f]))
            for e in ev[f]:
                if isinstance(e, int):
                    o.append(0); o.append(e)
                else:
                    o.append(1); var(o, len(e)); o.extend(e)
    if flags & 4:
        m = data['mouse']
        var(o, len(m)); p = 0
        for f, _, _ in m:
            var(o, f - p); p = f
        for c in (1, 2):
            prev = pm = 0
            for i, it in enumerate(m):
                mv = it[c] - prev
                cons = i > 0 and m[i][0] - m[i - 1][0] == 1
                zz(o, mv - pm if cons else mv)
                pm = mv if cons else 0
                prev = it[c]
    if flags & 8:
        changes(data['clicks'], bidx, flags & 32)
    o += b'LEN'
    var(o, frames_total)
    return bytes(o)


def encode_v2(d, frames_total):
    """version 2 writer (as before 2026-10), to compare the sizes"""
    def var(o, v):
        while v >= 0x80:
            o.append((v & 0x7F) | 0x80)
            v >>= 7
        o.append(v)

    def grouped(items):
        g = {}
        for it in items:
            g.setdefault(it[0], []).append(it[1:])
        return [(f, g[f]) for f in sorted(g)]

    data, keys, buttons = d['data'], d['keys'], d['buttons']
    flags = d['flags'] & 15
    o = bytearray(b'KADO\x02')
    o.append(flags)
    if flags & 1:
        var(o, len(keys))
        for k in keys: var(o, k)
    if flags & 8:
        var(o, len(buttons))
        for b in buttons: var(o, b)
    if flags & 1:
        g = grouped(data['inputs']); var(o, len(g)); p = 0
        for f, its in g:
            var(o, f - p); p = f; var(o, len(its))
            for k, dn in its: var(o, k << 1 | dn)
    if flags & 2:
        g = grouped(data['events']); var(o, len(g)); p = 0
        for f, its in g:
            var(o, f - p); p = f; var(o, len(its))
            for (e,) in its:
                if isinstance(e, int):
                    o.append(0); o.append(e)
                else:
                    o.append(1); var(o, len(e)); o.extend(e)
    if flags & 4:
        var(o, len(data['mouse'])); p = 0
        for f, x, y in data['mouse']:
            var(o, f - p); p = f; var(o, x); var(o, y)
    if flags & 8:
        g = grouped(data['clicks']); var(o, len(g)); p = 0
        for f, its in g:
            var(o, f - p); p = f; var(o, len(its))
            for b, dn in its: var(o, b << 1 | dn)
    o += b'LEN'
    var(o, frames_total)
    return bytes(o)
