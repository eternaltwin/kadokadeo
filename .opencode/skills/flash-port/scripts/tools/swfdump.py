"""Minimal SWF parser: dumps exported symbols, sprite timelines (PlaceObject2 matrices / color transforms)
and shape/bitmap bounds. Enough to understand how the Flash MovieClips are composed."""
import sys, zlib, struct

class Bits:
    def __init__(self, data, pos=0):
        self.d = data; self.pos = pos; self.bit = 0
    def align(self):
        if self.bit: self.bit = 0; self.pos += 1
    def ub(self, n):
        v = 0
        for _ in range(n):
            b = (self.d[self.pos] >> (7 - self.bit)) & 1
            v = (v << 1) | b
            self.bit += 1
            if self.bit == 8: self.bit = 0; self.pos += 1
        return v
    def sb(self, n):
        if n == 0: return 0
        v = self.ub(n)
        if v & (1 << (n - 1)): v -= 1 << n
        return v
    def fb(self, n): return self.sb(n) / 65536.0
    def u8(self): self.align(); v = self.d[self.pos]; self.pos += 1; return v
    def u16(self): self.align(); v = struct.unpack_from('<H', self.d, self.pos)[0]; self.pos += 2; return v
    def u32(self): self.align(); v = struct.unpack_from('<I', self.d, self.pos)[0]; self.pos += 4; return v
    def string(self):
        self.align(); e = self.d.index(0, self.pos); s = self.d[self.pos:e].decode('latin1'); self.pos = e + 1; return s
    def rect(self):
        self.align(); n = self.ub(5)
        r = [self.sb(n) / 20.0 for _ in range(4)]  # xmin xmax ymin ymax
        self.align(); return r
    def matrix(self):
        self.align()
        sx = sy = 1.0; r0 = r1 = 0.0
        if self.ub(1):
            n = self.ub(5); sx = self.fb(n); sy = self.fb(n)
        if self.ub(1):
            n = self.ub(5); r0 = self.fb(n); r1 = self.fb(n)
        n = self.ub(5); tx = self.sb(n) / 20.0; ty = self.sb(n) / 20.0
        self.align()
        return dict(a=sx, b=r0, c=r1, d=sy, tx=tx, ty=ty)
    def cxform(self, alpha=True):
        self.align()
        has_add = self.ub(1); has_mult = self.ub(1); n = self.ub(4)
        cnt = 4 if alpha else 3
        mult = [self.sb(n) / 256.0 for _ in range(cnt)] if has_mult else [1.0] * cnt
        add = [self.sb(n) for _ in range(cnt)] if has_add else [0] * cnt
        self.align()
        return dict(mult=mult, add=add)

def read_tags(data, pos, end):
    tags = []
    while pos < end:
        cl = struct.unpack_from('<H', data, pos)[0]; pos += 2
        code = cl >> 6; ln = cl & 0x3f
        if ln == 0x3f: ln = struct.unpack_from('<I', data, pos)[0]; pos += 4
        tags.append((code, data[pos:pos + ln]))
        pos += ln
        if code == 0: break
    return tags

def parse_place(code, body):
    b = Bits(body)
    if code == 4:  # PlaceObject
        cid = b.u16(); depth = b.u16(); m = b.matrix()
        return dict(depth=depth, char=cid, matrix=m, move=False)
    flags = b.u8()
    flags2 = b.u8() if code == 70 else 0
    depth = b.u16()
    r = dict(depth=depth, move=bool(flags & 1))
    if code == 70 and (flags2 & 0x08): r['className'] = b.string()
    if flags & 0x02: r['char'] = b.u16()
    if flags & 0x04: r['matrix'] = b.matrix()
    if flags & 0x08: r['cx'] = b.cxform(True)
    if flags & 0x10: r['ratio'] = b.u16()
    if flags & 0x20: r['name'] = b.string()
    if flags & 0x40: r['clipDepth'] = b.u16()
    return r

def main(path):
    raw = open(path, 'rb').read()
    sig = raw[:3]
    data = raw[:8] + (zlib.decompress(raw[8:]) if sig == b'CWS' else raw[8:])
    b = Bits(data, 8)
    frame = b.rect(); rate = b.u16() / 256.0; fc = b.u16()
    print('SWF', sig, 'v', raw[3], 'frame', frame, 'rate', rate, 'frames', fc)
    tags = read_tags(data, b.pos, len(data))
    chars = {}
    exports = {}
    sprites = {}
    for code, body in tags:
        bb = Bits(body)
        if code in (2, 22, 32, 83):
            cid = bb.u16(); r = bb.rect(); chars[cid] = ('shape', r)
        elif code in (20, 36):
            cid = bb.u16(); fmt = bb.u8(); w = bb.u16(); h = bb.u16(); chars[cid] = ('bitmap%d' % code, (w, h))
        elif code in (6, 21, 35, 90):
            cid = bb.u16(); chars[cid] = ('jpeg', None)
        elif code == 37:
            cid = bb.u16(); r = bb.rect(); chars[cid] = ('edittext', r)
        elif code in (10, 48, 75):
            cid = bb.u16(); chars[cid] = ('font', None)
        elif code in (11, 33):
            cid = bb.u16(); r = bb.rect(); chars[cid] = ('text', r)
        elif code == 39:
            cid = bb.u16(); nf = bb.u16()
            sub = read_tags(body, 4, len(body))
            frames = []; cur = []
            for sc, sbody in sub:
                if sc in (4, 26, 70):
                    cur.append(('place', parse_place(sc, sbody)))
                elif sc in (5, 28):
                    sb_ = Bits(sbody)
                    if sc == 5: sb_.u16()
                    cur.append(('remove', sb_.u16()))
                elif sc == 43:
                    cur.append(('label', Bits(sbody).string()))
                elif sc == 12:
                    cur.append(('action', len(sbody)))
                elif sc == 1:
                    frames.append(cur); cur = []
            chars[cid] = ('sprite', nf); sprites[cid] = frames
        elif code == 56 or code == 57:
            if code == 57: bb.string()
            n = bb.u16()
            for _ in range(n):
                t = bb.u16(); name = bb.string(); exports[t] = name
    return chars, exports, sprites

def fmt_m(m):
    if m is None: return ''
    s = 'tx=%.2f ty=%.2f' % (m['tx'], m['ty'])
    if m['a'] != 1 or m['d'] != 1: s += ' sx=%.4f sy=%.4f' % (m['a'], m['d'])
    if m['b'] or m['c']: s += ' r0=%.4f r1=%.4f' % (m['b'], m['c'])
    return s

def dump_sprite(chars, exports, sprites, cid, indent='', seen=None, max_frames=99):
    frames = sprites[cid]
    print('%sSPRITE %d (%s) frames=%d' % (indent, cid, exports.get(cid, ''), len(frames)))
    for i, fr in enumerate(frames[:max_frames]):
        if not fr: continue
        print('%s  frame %d:' % (indent, i + 1))
        for kind, v in fr:
            if kind == 'place':
                c = v.get('char')
                desc = ''
                if c is not None:
                    desc = '%s#%d %s' % (chars.get(c, ('?',))[0], c, chars.get(c, (None, ''))[1])
                    if c in exports: desc += ' [%s]' % exports[c]
                cx = v.get('cx')
                cxs = (' cx mult=%s add=%s' % ([round(x, 3) for x in cx['mult']], cx['add'])) if cx else ''
                print('%s    place d=%d%s %s %s%s%s' % (indent, v['depth'], ' MOVE' if v['move'] else '', desc,
                      fmt_m(v.get('matrix')), (' name=' + v['name']) if 'name' in v else '', cxs))
            else:
                print('%s    %s %s' % (indent, kind, v))

if __name__ == '__main__':
    chars, exports, sprites = main(sys.argv[1])
    print('EXPORTS', exports)
    want = sys.argv[2:] or None
    for cid in sorted(sprites):
        if want and str(cid) not in want and exports.get(cid) not in want: continue
        dump_sprite(chars, exports, sprites, cid)
