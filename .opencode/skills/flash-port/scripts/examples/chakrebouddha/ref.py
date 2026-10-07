"""Reference pages rendered from the SWF (swfrender) with the layout of pages.json (next to this file):
$KKP_WORK/chakrebouddha/check/ref<i>.png, to compare with the pages drawn by the game (ncheck.mjs -> run<i>.png) with
tools/cmp_pages.py. Item: [kind, frame, x, y, scale(, options)], x y in pixels of the canvas (2 per Flash pixel).
Vector shapes from the zoom 4 export, bitmap shapes (non-smoothed fills) from the zoom 1 export sampled with the
nearest pixel at the resolution of the page; the filters the code sets (GradientGlow / Glow / DropShadow, in stage
pixels) and the colour transforms applied like Flash (swfrender.apply_filter). The text fields (not drawn by swfrender):
the glyphs of the embedded font (its TTF) at the resolution of the page, laid out like Flash.
usage: python3 ref.py"""
import sys, json, os, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageDraw, ImageFont
import swfrender as R
import swfdump as SD
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'chakrebouddha', '')
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
GB = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)
GB.flash_replace = True
GB.nearest = True
COLORS = [0xD71E1B, 0xF49924, 0xF8CE06, 0x79A63F, 0x2388BE, 0x728DFC, 0xB23FA5]
SID = dict(chakra=71, active=54, lotus=16, neon=31, rock=39, mask=75)
H, Wd = 640, 600
CHECK = os.path.join(W, 'check')
os.makedirs(CHECK, exist_ok=True)


def strip_filters(cmds):
    """the commands without the filters of the timeline (drawn after, in stage pixels)"""
    out = []
    for c in cmds:
        if c[0] == 'layer':
            out += strip_filters(c[1])
        else:
            out.append(c)
    return out


def draw(g, sid, frame, x, y, k, rot=0.0, keep_filters=False, ctrl=None):
    """a clip at (x, y) canvas pixels, k canvas pixels per Flash pixel of the clip, rotated rot degrees"""
    c = dict(ctrl or {})
    c[sid] = frame
    c['__noactions__'] = True
    inst = R.Instance(g, sid, ctrl=c)
    Z = g.Z
    cr, sr = math.cos(math.radians(rot)), math.sin(math.radians(rot))
    M = dict(a=cr * k / Z, b=sr * k / Z, c=-sr * k / Z, d=cr * k / Z, tx=x / Z, ty=y / Z)
    cmds = []
    R.Renderer(g, 2).collect(inst, M, R.NOCX, set(), cmds)
    if not keep_filters:
        cmds = strip_filters(cmds)
    lay = np.zeros((H, Wd, 4), dtype=np.float32)
    R.Renderer(g, 2).draw(cmds, lay, (0, 0))
    return lay


def glow(lay, blur, strength, color, passes):
    return R.apply_filter(lay, dict(type='glow', color=((color >> 16) & 255, (color >> 8) & 255, color & 255, 255),
                                    blurX=blur, blurY=blur, strength=strength, passes=passes), 2)


def cx(lay, col):
    """ct.rgb = col, multipliers 0.3"""
    a = lay[..., 3:4]
    rgb = np.where(a > 0, lay[..., :3] / np.maximum(a, 1e-6), 0)
    add = np.array([(col >> 16) & 255, (col >> 8) & 255, col & 255], dtype=np.float32) / 255.0
    rgb = np.clip(rgb * 0.3 + add, 0, 1)
    return np.concatenate([rgb * a, a], axis=-1).astype(np.float32)


# text: Ginko 25 (DefineFont3 layout) from its TTF
TX = swftext.all_edittexts(W + 'gfx.swf')
raw = open(W + 'gfx.swf', 'rb').read()
DATA = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
_hb = SD.Bits(DATA, 8)
_hb.rect(); _hb.u16(); _hb.u16()
TAGS = SD.read_tags(DATA, _hb.pos, len(DATA))


def font_layout(fid):
    for code, body in TAGS:
        if code not in (48, 75) or struct.unpack_from('<H', body, 0)[0] != fid:
            continue
        em = 20480.0 if code == 75 else 1024.0
        _, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
        wide = flags & 0x08
        base = q
        q += ng * (4 if wide else 2)
        q = base + struct.unpack_from('<I' if wide else '<H', body, q)[0]
        codes = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)]
        q += 2 * ng
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        return dict(ascent=asc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})


FONT = font_layout(5)
TTF = W + 'fonts_gfx/5_Ginko.ttf'


def text_field(tid, place, s, x, y, k):
    """field tid placed at `place` in its clip, text s, the clip at (x, y) canvas pixels, scale k"""
    t = TX[tid]
    b = t['bounds']
    size = t['height']
    x0, x1 = place[0] + b[0] + 2, place[0] + b[1] - 2
    base = place[1] + b[2] + 2 + FONT['ascent'] * size
    width = sum(FONT['adv'][c] for c in s) * size
    pen = x0 + (x1 - x0 - width) / 2
    SS = 4
    big = Image.new('L', (Wd * SS, H * SS), 0)
    font = ImageFont.truetype(TTF, int(round(size * k * SS)))
    d = ImageDraw.Draw(big)
    for c in s:
        d.text(((x + pen * k) * SS, (y + base * k) * SS), c, font=font, fill=255, anchor='ls')
        pen += FONT['adv'][c] * size
    a = np.asarray(big.resize((Wd, H), Image.LANCZOS), dtype=np.float32) / 255.0
    lay = np.stack([a, a, a, a], axis=-1)
    # the field's DropShadow / Glow (black, 3, strength 1, quality 3)
    return glow(lay, 3, 1, 0x000000, 3)


def over(dst, src):
    dst *= (1 - src[..., 3:4])
    dst += src


pages = json.load(open(os.path.join(HERE, 'pages.json')))
for pi, page in enumerate(pages):
    canvas = np.zeros((H, Wd, 4), dtype=np.float32)
    canvas[...] = [0x33 / 255, 0x55 / 255, 0x66 / 255, 1]
    for item in page:
        kind, frame, x, y, sc = item[:5]
        opt = item[5] if len(item) > 5 else {}
        k = 2 * sc
        if kind == 'chakra':
            lay = draw(G, SID['chakra'], frame, x, y, k)
            if 'glow' in opt:
                col = COLORS[frame - 1]
                lay = glow(lay, 2, 2, col, 3)
                lay = glow(lay, 8, opt['glow'], col, 3)
        elif kind == 'active':
            lay = draw(G, SID['active'], frame, x, y, k)
            if frame == 1:
                lay = glow(lay, 8, 1, 0xFFFFFF, 1)
            lay = cx(lay, opt['cx'])
        elif kind == 'lotus':
            lay = draw(GB, SID['lotus'], frame, x, y, k, rot=opt.get('rot', 0))
            if opt.get('glow'):
                lay = glow(lay, 32, 1, opt['color'], 1)
            lay = cx(lay, opt['color'])
        elif kind == 'points':
            lay = text_field(40, (-40, -15), opt['text'], x, y, k)
        elif kind == 'bonus':
            lay = text_field(6, (-50, -31.2), TX[6]['text'].upper(), x, y, k)
            over(lay, text_field(7, (-50, -6.95), TX[7]['text'], x, y, k))
        elif kind == 'energy':
            bg = draw(GB, 80, 1, x, y, k, ctrl=None) * 0
            # mcBg: shape 77, mcMask at (0, mask) as the mask of shape 79
            Z = GB.Z
            lay = np.zeros((H, Wd, 4), dtype=np.float32)
            for cid in (77, 79):
                cm = [('shape', cid, dict(a=k / Z, b=0, c=0, d=k / Z, tx=x / Z, ty=y / Z), R.NOCX)]
                L = np.zeros((H, Wd, 4), dtype=np.float32)
                R.Renderer(GB, 2).draw(cm, L, (0, 0))
                if cid == 79:
                    mk = draw(G, SID['mask'], 1, x, y + opt['mask'] * k, k)
                    L *= np.clip(mk[..., 3:4], 0, 1)
                over(lay, L)
        else:
            lay = draw(GB, SID[kind], frame, x, y, k)
        over(canvas, lay)
    im = Image.fromarray(np.clip(canvas[..., :3] * 255 + 0.5, 0, 255).astype(np.uint8), 'RGB')
    im.save(os.path.join(CHECK, 'ref%d.png' % pi))
    print('ref%d.png' % pi)
