"""Builds the Paradice graphics for KadoKadeo from the original SWF files (gfx.swf, part.swf, decor.swf).

Every symbol the game attaches is exported as a Clip (timeline tables played by paradice.Clip, see clipexport.py):
  - the penguin keeps its body `b` (40 looks, one drawn at random: frame 40 is the chick, `piou`, which the code reads)
    and its arms / feet (stopped on a random frame by their own script) as nested clips;
  - the ball keeps its gem `b` (the code chooses the colour, the ice and the specials) and has white silhouettes: the
    code whitens it before it explodes (Cs.setPercentColor = tint + added colour); its random _alpha (45 to 90) is
    applied by Flash to each shape (and shape layer) on its own: the gem body (an opaque square under the rest of
    shape 184) stays almost opaque, only the white glass lets the background through. The ball is exported
    `stack`ed: its layers cut in slices of shapes that do not overlap, so that Pixi does the same;
  - the bitmaps (portraits of the special balls, panel of the multiplier, background, window frame) are kept at their
    native resolution, drawn x2;
  - the numbers of the score bubbles (Impact, embedded in part.swf) and the text of the multiplier panel (Verdana Bold
    Italic, a device font: drawn from the system font) are glyph images placed at run time like Flash lays out
    their text field.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: paradice_assets.py <out dir>
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from PIL import Image, ImageFont, ImageDraw
from fontTools.ttLib import TTFont
import swfrender as R
import swfdump as SD
import swftext as ST
import clipexport as C

OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

from paradice_swf import W, G, G1, Gq, Gd, bitmap_shapes

K = C.K


def rng(*ranges):
    out = []
    for a, b in ranges:
        out += list(range(a, b + 1))
    return out


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM_G = {
    (45, 1): [['r', 1, 50]],          # penguin eye: gotoAndPlay(random(50) + 1)
    (59, 1): [['x', 'pickB']],        # penguin body: gotoAndStop(random(40) + 1) (random(39) + 1 once _parent.piou is set)
    (59, 40): [['x', 'piou']],        # the chick: _parent.piou = true
    (61, 1): [['x', 'limb']],         # arm / foot: if (_parent.b._currentframe == 40) gotoAndStop(15) else gotoAndStop(random(10) + 1)
    (65, 1): [['x', 'limb']],
    (100, 14): [['x', 'rmSelf']],     # mcPyro: removeMovieClip("")
    (136, 46): [['x', 'rmSelf']],     # mcMultiPanel
    (146, 7): [['x', 'rmSelf']],      # mcOnde
    (179, 19): [['x', 'rmSelf']],     # mcExplode
}
# penguin frames the code can reach: base (stop), catch, pass, launch, take, burn, peace (until their stop) and hoNo
# (its end loops on "loop")
PIN_FRAMES = rng((1, 1), (6, 8), (17, 24), (29, 43), (45, 56), (59, 67), (69, 105), (107, 124))

E = C.Exporter(G, SRC, '', CUSTOM_G)
E.bitmaps = (G1, bitmap_shapes('gfx'))
E.white_solid = True              # the chick's beak: the eye clip under a solid colour on frame 40 of the body only
E.export(83, 'pinguin', code=('b',), frames=PIN_FRAMES)
E.export(201, 'ball', code=('b',), white=True, stack=True)   # root._alpha = 45..90: per shape, as in Flash
E.export(100, 'pyro', code=('sub',))
E.export(136, 'multiPanel')
E.export(115, 'partFlame')
E.export(85, 'partIceBlast')
E.export(150, 'partPixel')
E.export(146, 'onde')
# the explosion flattened (1.6 Mpx for its 18 frames of up to 270 x 230 px; as images moved by matrices it takes 4.4 Mpx:
# its big frame by frame shapes, the three tinted copies of shapes 1-19 needing white silhouettes)
E.export(179, 'explode', strategy='flat')
E.export(181, 'grenade')
E.export(183, 'bomb')

Eq = C.Exporter(Gq, SRC, 'q', {})
Eq.export(14, 'partIce')
Eq.export(9, 'scoreBubble', strategy='cut', code=('bubble',))
Eq.export(3, 'groundLimit', frames=[1])

Ed = C.Exporter(Gd, SRC, 'd', {})
Ed.export(10, 'bg', strategy='flat', res=0.5)
Ed.export(4, 'cache', strategy='flat', res=0.5)

clips, pivots, area = {}, {}, {}
for X in (E, Eq, Ed):
    for k in X.clips:
        assert k not in clips, k
    clips.update(X.clips)
    pivots.update(X.pivots)
    area.update(X.area)


def drop_text_layer(cname, tid, prefix):
    """the layer of a text field (no image: drawn at run time) leaves the clip"""
    c = clips[cname]
    keep = []
    for L in c['layers']:
        if L['k'] == 1 and L['a'] == '%sl%d' % (prefix, tid):
            for a in (L['a'], L['a'] + 'W'):
                if a in area:
                    shutil.rmtree(os.path.join(SRC, a))
                    area.pop(a)
                    pivots.pop(a)
            continue
        keep.append(L)
    assert len(keep) == len(c['layers']) - 1, cname
    c['layers'] = keep


def name_layer(cname, anim, nm):
    ls = [L for L in clips[cname]['layers'] if L['a'] == anim]
    assert len(ls) == 1, (cname, anim)
    ls[0]['nm'] = nm


drop_text_layer('scoreBubble', 8, 'q')
# the panel board (sprite 120: bitmap + the text field "_parent.score"): named for the code, which writes the text in it
name_layer('multiPanel', 'l120', 'board')

meta = {}

# ---------------------------------------------------------------- text fields
TQ = ST.all_edittexts(W + 'part.swf')
TG = ST.all_edittexts(W + 'gfx.swf')


def font_layouts(path):
    """DefineFont2 / 3 layouts: font id -> codes, ascent, advances (em fractions)"""
    raw = open(path, 'rb').read()
    data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
    bb = SD.Bits(data, 8); bb.rect(); bb.u16(); bb.u16()
    out = {}
    for code, body in SD.read_tags(data, bb.pos, len(data)):
        if code not in (48, 75):
            continue
        em = 20480.0 if code == 75 else 1024.0
        fid, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
        if ng == 0:
            continue    # a device font (no glyphs)
        wide = flags & 0x08
        wide_codes = code == 75 or (flags & 0x04)
        base = q
        q += ng * (4 if wide else 2)
        cto = struct.unpack_from('<I' if wide else '<H', body, q)[0]
        q = base + cto
        if wide_codes:
            codes = [struct.unpack_from('<H', body, q + 2 * i)[0] for i in range(ng)]
            q += 2 * ng
        else:
            codes = list(body[q:q + ng])
            q += ng
        assert flags & 0x80, 'font %d without layout' % fid
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        out[fid] = dict(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


def ttf_layout(path, chars):
    """layout of a TrueType font (device font of the player): ascent, descent, advances (em fractions)"""
    f = TTFont(path)
    em = float(f['head'].unitsPerEm)
    cmap = f.getBestCmap()
    hm = f['hmtx']
    return dict(ascent=f['hhea'].ascent / em, descent=-f['hhea'].descent / em,
                adv={c: hm[cmap[ord(c)]][0] / em for c in chars})


def glyph_anims(name, ttf, lay, chars, size, color):
    """one image per character, its pivot on the pen position at the baseline (white glyphs: tinted at run time)"""
    SS = 4
    font = ImageFont.truetype(ttf, int(round(size * K * SS)))
    pad = 4
    w = int(math.ceil(max(lay['adv'][c] for c in chars) * size * K)) + 2 * pad + 8
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * K)) + 2 * pad + 2
    ox, oy = pad + 3, pad + int(math.ceil(lay['ascent'] * size * K))
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    rgb = tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))
    for i, ch in enumerate(chars):
        big = Image.new('L', (w * SS, h * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.LANCZOS)
        g = Image.new('RGBA', (w, h), rgb + (0,))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    area[name] = w * h * len(chars)
    return dict(anim=name, chars=chars, adv=[round(lay['adv'][c] * size, 4) for c in chars])


def field_info(X, T, sid, tid, glyphs, lay):
    """Flash text field layout (2 px gutter, first baseline = top + 2 + ascent) in the coordinates of sprite sid"""
    inst = R.Instance(X, sid, ctrl={'__noactions__': True})
    e = [e for e in inst.display.values() if e['char'] == tid][0]
    m, t = e['matrix'], T[tid]
    x0, x1, y0 = t['bounds'][0], t['bounds'][1], t['bounds'][2]
    # (the field matrices are translations, up to 0.2 % of scale)
    assert abs(m['a'] - 1) < 3e-3 and abs(m['d'] - 1) < 3e-3 and m['b'] == 0 and m['c'] == 0, m
    info = dict(glyphs)
    info.update(x=round(m['tx'] + x0 + 2, 3), w=round(x1 - x0 - 4, 3),
                base=round(m['ty'] + y0 + 2 + lay['ascent'] * t['height'], 3), center=t['align'] == 'center')
    return info


# score bubble: "field", Impact embedded in part.swf, colour set by the code (ScoreBubble.TEXTCOLOR)
fq = font_layouts(W + 'part.swf')
tb = TQ[8]
assert tb['useOutlines'] and tb['font'] in fq
lay = fq[tb['font']]
meta['bubbleField'] = field_info(Gq, TQ, 9, 8, glyph_anims('glyphBubble', W + 'fonts_part/7_impact.ttf', lay, '0123456789',
                                                          tb['height'], '#ffffff'), lay)
# _width of "bubble" before the code sets it (setScore: bubble._width = textWidth + 24): sprite 6 on its first frame
inst = R.Instance(Gq, 6, ctrl={'__noactions__': True})
rd = R.Renderer(Gq, 1)
cmds = []
rd.collect(inst, R.IDENT, R.NOCX, set(), cmds)
b = rd.bounds(cmds)
meta['bubbleW'] = round(b[2] - b[0], 4)

# multiplier panel: "_parent.score" in sprite 120, Verdana Bold Italic as a device font (not embedded)
tp = TG[119]
assert not tp['useOutlines'] and tp['fontInfo']['name'] == 'Verdana' and tp['fontInfo']['bold'] and tp['fontInfo']['italic']
VERDANA = '/System/Library/Fonts/Supplemental/Verdana Bold Italic.ttf'
lay = ttf_layout(VERDANA, 'x0123456789')
meta['panelField'] = field_info(G, TG, 120, 119, glyph_anims('glyphPanel', VERDANA, lay, 'x0123456789', tp['height'], tp['color']), lay)
# the board layer: texture pixels per Flash pixel of its picture (a bitmap at its native resolution)
# (sprite 120 is placed at scale 1: the scale of the layer matrix is res of the clip / res of the picture)
board = [L for L in clips['multiPanel']['layers'] if L.get('nm') == 'board'][0]
bm = board['m0'] if 'm0' in board else [m for m in board['m'] if m][0]
meta['boardRes'] = round(clips['multiPanel']['r'] / bm[2], 4)

print('bubbleField', meta['bubbleField'])
print('panelField', meta['panelField'])
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6,
                                                                    E.warnings + Eq.warnings + Ed.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
