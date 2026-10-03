"""The SWF of Magmax for swfrender, with what it cannot draw added: the sprites drawn with morph shapes (FFDec renders,
frame by frame) and the static texts of the combo messages (drawn from the embedded font). Used by magmax_assets.py
and ref.py."""
import os, sys, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'magmax', '')   # SWF + FFDec exports (see rebuild_assets.sh)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
Gp = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)      # the background bitmap at its native resolution
Gb = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)      # untouched timelines, for the bounds (hitTest)
for X in (G, Gp, Gb):
    X.flash_replace = True

swf_raw = open(W + 'gfx.swf', 'rb').read()
SWF_DATA = swf_raw[:8] + (zlib.decompress(swf_raw[8:]) if swf_raw[:3] == b'CWS' else swf_raw[8:])


def swf_tags():
    bb = SD.Bits(SWF_DATA, 8)
    bb.rect(); bb.u16(); bb.u16()
    return SD.read_tags(SWF_DATA, bb.pos, len(SWF_DATA))


# ---------------------------------------------------------------- morph shapes: FFDec renders of their sprites
# sprite id -> folder of `ffdec -format sprite:png -zoom 4 -export sprite` (rebuild_assets.sh). FFDec draws every
# frame on one canvas whose origin is the top left corner of the union of the sprite's shape rectangles (checked on
# the last frame of each, a plain shape). Each frame becomes a pseudo shape replacing the sprite's display list.
MORPH_SPRITES = {165: 'DefineSprite_165', 202: 'DefineSprite_202_hammer_shoot_fireball'}


def inject_ffdec_sprite(X, sid, folder):
    sd = X.sprites[sid]
    chars = {v['char'] for ops in sd.frames for k, v in ops if k == 'place' and 'char' in v}
    rects = [X.shapes[c] for c in chars]
    ox, oy = min(r[0] for r in rects), min(r[2] for r in rects)
    frames = []
    for f in range(1, sd.nframes + 1):
        im = Image.open(W + 'spr4_gfx/%s/%d.png' % (folder, f)).convert('RGBA')
        pid = 100000 + sid * 100 + f
        X.shapes[pid] = [ox, ox + im.width / X.Z, oy, oy + im.height / X.Z]
        X._shape_cache[pid] = im
        frames.append([('place', dict(depth=1, char=pid, matrix=R.IDENT, move=f > 1))])
    sd.frames = frames


for sid, folder in MORPH_SPRITES.items():
    inject_ffdec_sprite(G, sid, folder)


# ---------------------------------------------------------------- static texts (DefineText) of the combo messages
def font_codes():
    """DefineFont2 / 3 of the SWF: font id -> glyph index -> character code"""
    out = {}
    for code, body in swf_tags():
        if code not in (48, 75):
            continue
        fid, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
        wide = flags & 0x08
        base = q
        q += ng * (4 if wide else 2)
        cto = struct.unpack_from('<I' if wide else '<H', body, q)[0]
        q = base + cto
        if code == 75 or (flags & 0x04):
            out[fid] = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)]
        else:
            out[fid] = list(body[q:q + ng])
    return out


def static_texts():
    """DefineText: id -> (bounds, matrix, records [font, colour, x, y, height, [(glyph, advance)]]) (px)"""
    out = {}
    for code, body in swf_tags():
        if code not in (11, 33):
            continue
        b = SD.Bits(body)
        cid = b.u16()
        rect = b.rect()
        m = b.matrix()
        gb, ab = b.u8(), b.u8()
        recs, font, col, x, y, h = [], None, (0, 0, 0, 255), 0.0, 0.0, 0.0
        while True:
            flags = b.u8()
            if flags == 0:
                break
            if flags & 0x08:
                font = b.u16()
            if flags & 0x04:
                col = (b.u8(), b.u8(), b.u8(), b.u8() if code == 33 else 255)
            if flags & 0x01:
                x = struct.unpack('<h', struct.pack('<H', b.u16()))[0] / 20.0
            if flags & 0x02:
                y = struct.unpack('<h', struct.pack('<H', b.u16()))[0] / 20.0
            if flags & 0x08:
                h = b.u16() / 20.0
            n = b.u8()
            glyphs = [(b.ub(gb), b.sb(ab) / 20.0) for _ in range(n)]
            recs.append(dict(font=font, col=col, x=x, y=y, h=h, glyphs=glyphs))
        out[cid] = (rect, m, recs)
    return out


TTF = {27: W + 'fonts_gfx/27_impact.ttf'}


def inject_texts(X):
    codes = font_codes()
    SS = 4
    for cid, (rect, m, recs) in static_texts().items():
        assert m['a'] == 1 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0, cid
        x0, x1, y0, y1 = rect[0] - 1, rect[1] + 1, rect[2] - 1, rect[3] + 1
        Z = X.Z * SS
        big = Image.new('RGBA', (int(math.ceil((x1 - x0) * Z)), int(math.ceil((y1 - y0) * Z))), (0, 0, 0, 0))
        for r in recs:
            font = ImageFont.truetype(TTF[r['font']], int(round(r['h'] * Z)))
            layer = Image.new('L', big.size, 0)
            dr = ImageDraw.Draw(layer)
            px = r['x']
            for g, adv in r['glyphs']:
                ch = chr(codes[r['font']][g])
                dr.text(((px + m['tx'] - x0) * Z, (r['y'] + m['ty'] - y0) * Z), ch, font=font, fill=255, anchor='ls')
                px += adv
            fill = Image.new('RGBA', big.size, r['col'][:3] + (0,))
            fill.putalpha(layer.point(lambda v: v * r['col'][3] // 255))
            big = Image.alpha_composite(big, fill)
        im = big.resize((big.width // SS, big.height // SS), Image.LANCZOS)
        X.shapes[cid] = [x0, x0 + im.width / X.Z, y0, y0 + im.height / X.Z]
        X._shape_cache[cid] = im


inject_texts(G)
