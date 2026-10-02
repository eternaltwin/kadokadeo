"""PlaceObject3 filter list / blend mode reader (SWF 8)"""
import struct

FILTER_NAMES = {0: 'dropshadow', 1: 'blur', 2: 'glow', 3: 'bevel', 4: 'gradientglow', 5: 'convolution', 6: 'colormatrix', 7: 'gradientbevel'}
BLEND_NAMES = {0: 'normal', 1: 'normal', 2: 'layer', 3: 'multiply', 4: 'screen', 5: 'lighten', 6: 'darken', 7: 'difference',
               8: 'add', 9: 'subtract', 10: 'invert', 11: 'alpha', 12: 'erase', 13: 'overlay', 14: 'hardlight'}


def fixed(v):
    return v / 65536.0


def fixed8(v):
    return v / 256.0


def read_filters(buf, pos):
    n = buf[pos]; pos += 1
    out = []
    for _ in range(n):
        fid = buf[pos]; pos += 1
        f = {'type': FILTER_NAMES.get(fid, fid)}
        if fid == 0:  # drop shadow
            r, g, b, a = buf[pos:pos + 4]; pos += 4
            bx, by, ang, dist = struct.unpack_from('<iiii', buf, pos); pos += 16
            st, = struct.unpack_from('<H', buf, pos); pos += 2
            fl = buf[pos]; pos += 1
            f.update(color=(r, g, b, a), blurX=fixed(bx), blurY=fixed(by), angle=fixed(ang), distance=fixed(dist), strength=fixed8(st),
                     inner=bool(fl & 0x80), knockout=bool(fl & 0x40), passes=fl & 0x1f)
        elif fid == 1:  # blur
            bx, by = struct.unpack_from('<ii', buf, pos); pos += 8
            fl = buf[pos]; pos += 1
            f.update(blurX=fixed(bx), blurY=fixed(by), passes=fl >> 3)
        elif fid == 2:  # glow
            r, g, b, a = buf[pos:pos + 4]; pos += 4
            bx, by = struct.unpack_from('<ii', buf, pos); pos += 8
            st, = struct.unpack_from('<H', buf, pos); pos += 2
            fl = buf[pos]; pos += 1
            f.update(color=(r, g, b, a), blurX=fixed(bx), blurY=fixed(by), strength=fixed8(st), inner=bool(fl & 0x80),
                     knockout=bool(fl & 0x40), passes=fl & 0x1f)
        elif fid == 3:  # bevel
            sh = buf[pos:pos + 4]; hl = buf[pos + 4:pos + 8]; pos += 8
            bx, by, ang, dist = struct.unpack_from('<iiii', buf, pos); pos += 16
            st, = struct.unpack_from('<H', buf, pos); pos += 2
            fl = buf[pos]; pos += 1
            f.update(shadow=tuple(sh), highlight=tuple(hl), blurX=fixed(bx), blurY=fixed(by), angle=fixed(ang), distance=fixed(dist),
                     strength=fixed8(st), inner=bool(fl & 0x80), knockout=bool(fl & 0x40), ontop=bool(fl & 0x10), passes=fl & 0x0f)
        elif fid in (4, 7):  # gradient glow / bevel
            nc = buf[pos]; pos += 1
            cols = [tuple(buf[pos + 4 * i:pos + 4 * i + 4]) for i in range(nc)]; pos += 4 * nc
            ratios = list(buf[pos:pos + nc]); pos += nc
            bx, by, ang, dist = struct.unpack_from('<iiii', buf, pos); pos += 16
            st, = struct.unpack_from('<H', buf, pos); pos += 2
            fl = buf[pos]; pos += 1
            f.update(colors=cols, ratios=ratios, blurX=fixed(bx), blurY=fixed(by), angle=fixed(ang), distance=fixed(dist),
                     strength=fixed8(st), inner=bool(fl & 0x80), knockout=bool(fl & 0x40), ontop=bool(fl & 0x10), passes=fl & 0x0f)
        elif fid == 5:  # convolution
            mx, my = buf[pos], buf[pos + 1]; pos += 2
            pos += 8 + 4 * mx * my + 4 + 1
        elif fid == 6:  # color matrix
            m = struct.unpack_from('<20f', buf, pos); pos += 80
            f.update(matrix=m)
        out.append(f)
    return out, pos


def parse_place3_extras(body):
    """returns (filters, blend) of a PlaceObject3 body"""
    f1, f2 = body[0], body[1]
    pos = 2
    pos += 2  # depth
    if f2 & 0x08:  # class name
        while body[pos] != 0:
            pos += 1
        pos += 1
    if f1 & 0x02:
        pos += 2  # char id
    import swfdump as S
    b = S.Bits(body, pos)
    if f1 & 0x04:
        b.matrix()
    if f1 & 0x08:
        b.cxform(True)
    pos = b.pos
    if f1 & 0x10:
        pos += 2  # ratio
    if f1 & 0x20:
        while body[pos] != 0:
            pos += 1
        pos += 1
    if f1 & 0x40:
        pos += 2  # clip depth
    filters, blend = [], None
    if f2 & 0x01:
        filters, pos = read_filters(body, pos)
    if f2 & 0x02:
        blend = BLEND_NAMES.get(body[pos], body[pos]); pos += 1
    return filters, blend
