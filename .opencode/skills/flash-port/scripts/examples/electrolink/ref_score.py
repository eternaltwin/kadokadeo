"""Reference pictures of the scoring texts: FFDec renders of copies of game.swf whose text fields _pts / _mult hold
the given values (sprite 14, with its filters), to compare with the pictures composed by TextGfx.hx.
usage: ref_score.py <out dir> <pts>:<mult> ...      (writes <out>/ref_<pts>_<mult>.png at 2 px per Flash pixel)"""
import os, sys, struct, zlib, subprocess, shutil
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD
import swftext
from PIL import Image

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'electrolink', '')
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
FF = os.environ.get('FFDEC', 'java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar').split()
TX = swftext.all_edittexts(W + 'game.swf')
raw = open(W + 'game.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(DATA, 8)
hb.rect(); hb.u16(); hb.u16()
END = hb.pos
TAGS = SD.read_tags(DATA, END, len(DATA))


def html_field(cid, text):
    t = TX[cid]['text']
    i = t.index('kerning="1">') + len('kerning="1">')
    j = t.index('</font>')
    return t[:i] + text + t[j:]


def patched(path, texts):
    out = bytearray()
    for code, body in TAGS:
        if code == 37:
            cid = struct.unpack_from('<H', body, 0)[0]
            if cid in texts:
                old = TX[cid]['text'].encode('latin1')
                assert body.endswith(old + b'\0'), cid
                body = body[:len(body) - len(old) - 1] + texts[cid].encode('latin1') + b'\0'
        if len(body) < 63 and code not in (6, 21, 35, 20, 36, 90):
            out += struct.pack('<H', (code << 6) | len(body))
        else:
            out += struct.pack('<HI', (code << 6) | 63, len(body))
        out += body
    data = bytearray(b'FWS') + DATA[3:4] + b'\0\0\0\0' + DATA[8:END] + out
    struct.pack_into('<I', data, 4, len(data))
    open(path, 'wb').write(data)


for arg in sys.argv[2:]:
    pts, mult = arg.split(':')
    tmp = os.path.join(OUT, 'tmp')
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    swf = os.path.join(tmp, 'p.swf')
    patched(swf, {10: html_field(10, pts), 13: html_field(13, mult)})
    subprocess.run(FF + ['-onerror', 'ignore', '-format', 'sprite:png', '-zoom', '2', '-selectid', '14', '-export', 'sprite',
                         tmp, swf], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    d = [x for x in os.listdir(tmp) if x.startswith('DefineSprite_14')][0]
    Image.open(os.path.join(tmp, d, '1.png')).save(os.path.join(OUT, 'ref_%s_%s.png' % (pts, mult)))
    shutil.rmtree(tmp)
    print('ref', pts, mult)
