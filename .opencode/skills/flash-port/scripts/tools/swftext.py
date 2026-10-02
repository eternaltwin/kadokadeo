"""DefineEditText reader (SWF tag 37)"""
import struct, sys, zlib
sys.path.insert(0, __import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import swfdump as S


def parse_edittext(body):
    cid = struct.unpack_from('<H', body, 0)[0]
    b = S.Bits(body, 2)
    bounds = b.rect()
    pos = b.pos
    f1, f2 = body[pos], body[pos + 1]; pos += 2
    r = dict(id=cid, bounds=bounds, wordWrap=bool(f1 & 0x40), multiline=bool(f1 & 0x20), readOnly=bool(f1 & 0x08),
             autoSize=bool(f2 & 0x40), html=bool(f2 & 0x02), useOutlines=bool(f2 & 0x01), noSelect=bool(f2 & 0x10))
    if f1 & 0x01:
        r['font'] = struct.unpack_from('<H', body, pos)[0]; pos += 2
    if f2 & 0x80:
        e = body.index(0, pos); r['fontClass'] = body[pos:e].decode('latin1'); pos = e + 1
    if f1 & 0x01:
        r['height'] = struct.unpack_from('<H', body, pos)[0] / 20.0; pos += 2
    if f1 & 0x04:
        r['color'] = '#%02x%02x%02x' % tuple(body[pos:pos + 3]); r['alpha'] = body[pos + 3] / 255.0; pos += 4
    if f1 & 0x02:
        r['maxLength'] = struct.unpack_from('<H', body, pos)[0]; pos += 2
    if f2 & 0x20:
        r['align'] = ['left', 'right', 'center', 'justify'][body[pos]]
        r['leftMargin'], r['rightMargin'], r['indent'], r['leading'] = struct.unpack_from('<HHHh', body, pos + 1)
        r['leftMargin'] /= 20.0; r['rightMargin'] /= 20.0; r['indent'] /= 20.0; r['leading'] /= 20.0
        pos += 9
    e = body.index(0, pos); r['variable'] = body[pos:e].decode('latin1'); pos = e + 1
    if f1 & 0x80:
        e = body.index(0, pos); r['text'] = body[pos:e].decode('latin1'); pos = e + 1
    return r


def all_edittexts(path):
    raw = open(path, 'rb').read()
    data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
    b = S.Bits(data, 8); b.rect(); b.u16(); b.u16()
    tags = S.read_tags(data, b.pos, len(data))
    fonts, out = {}, {}
    for code, body in tags:
        if code in (48, 75):
            fid = struct.unpack_from('<H', body, 0)[0]
            nl = body[4]
            fonts[fid] = dict(name=body[5:5 + nl].decode('latin1').rstrip('\x00'), bold=bool(body[2] & 0x01), italic=bool(body[2] & 0x02))
        elif code == 37:
            r = parse_edittext(body)
            out[r['id']] = r
    for r in out.values():
        if 'font' in r:
            r['fontInfo'] = fonts.get(r['font'])
    return out


if __name__ == '__main__':
    for k, v in sorted(all_edittexts(sys.argv[1]).items()):
        print(k, v)
