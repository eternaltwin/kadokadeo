"""Builds the Quadrikolor graphics for KadoKadeo from the original SWF (gfx.swf: the graphics of the released
taupebille.swf, same shapes and timelines, readable export and instance names).

Every symbol the game attaches is exported as a Clip (timeline tables played by quadrikolor.Clip, see clipexport.py):
  - the background (a 300 x 300 bitmap, kept at its native resolution), the corner holes (`trou`, drawn at 70 %,
    with their 7 jets of particles that start on a random frame), the ship (its reactor `reacteur` played by the
    code), the trail (`queue`), the ignition spark, the bounce marks of the aiming line (`lineseg`);
  - the balls: Ball.initColor gives `base` the colour transform {ra: 100, rb: r - 255, ...} (multiplier 100, negative
    offsets: no tint can do it) and stores it in mc.color, which the frame scripts of the nested clips copy
    (Mc.setColor(this, _parent.color) on `base` and on the rolling ball 124, Mc.setColor(b, _parent.color) on 106):
    one baked copy of the ball per colour (`ball0`..`ball6`, and `slotball0`..`slotball6`: frame 1 at half size for the
    score sheet). The death drop 117 calls Mc.setColor(b, ...) without a child `b`: no colour (Color(undefined));
  - the interface: the bar (`carburant` / `puissance`), the 14 gauge squares (`square`, its colour `s` driven by the
    code) and the lines of the score sheet (`scoreSlot`, its border `bord` driven by the code).
The static texts (DefineText: CARBURANT, PUISSANCE, the bonus lines of the score sheet) are not drawn by swfrender:
their FFDec SVG export (exact glyph outlines) is rendered like a shape. The text fields the code writes (points and
multiplier of a score line, multiplier of the bar) only ever show a few values: each value is one picture, laid out
like a Flash text field with the glyphs of the font embedded in the SWF (`txtPts`, `txtMult`, `txtMulti`).
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: quadrikolor_assets.py <out dir>     (after prepare_game.sh and the FFDec text export, see rebuild_assets.sh)
"""
import os, sys, json, shutil, math, struct, zlib, glob, subprocess, io
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from PIL import Image
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD
import logging
logging.getLogger('fontTools').setLevel(logging.ERROR)

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'quadrikolor', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)
K = C.K

RAW = open(W + 'gfx.swf', 'rb').read()
DATA = RAW[:8] + (zlib.decompress(RAW[8:]) if RAW[:3] == b'CWS' else RAW[8:])
_b = SD.Bits(DATA, 8); _b.rect(); _b.u16(); _b.u16()
TAGS = SD.read_tags(DATA, _b.pos, len(DATA))

# Const.COLORS
COLORS = [0xDD0000, 0xEEAA00, 0xDDEE22, 0x33DD22, 0x22AA88, 0x4488EE, 0xAA55DD]


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


def bitmap_shapes():
    """ids of the shapes filled with a bitmap (FFDec SVG export: a pattern fill)"""
    return sorted(int(os.path.basename(f)[:-4]) for f in glob.glob(W + 'svg_gfx/*.svg') if 'pattern' in open(f).read())


def rsvg(svg, z):
    r = subprocess.run(['rsvg-convert', '-z', str(z)], input=svg.encode(), capture_output=True, check=True)
    return Image.open(io.BytesIO(r.stdout)).convert('RGBA')


def static_text_rects():
    """DefineText id -> bounds [xmin, xmax, ymin, ymax]"""
    out = {}
    for code, body in TAGS:
        if code in (11, 33):
            bb = SD.Bits(body, 2)
            out[struct.unpack_from('<H', body, 0)[0]] = bb.rect()
    return out


def add_static_texts(G):
    """the static texts drawn as shapes: the FFDec SVG export of each (origin: the top left of its bounds)"""
    for tid, rect in static_text_rects().items():
        p = W + 'txt_gfx/%d.svg' % tid
        im = rsvg(open(p).read(), G.Z)
        G.shapes[tid] = list(rect)
        G._shape_cache[tid] = im


def new_swf(color=None):
    G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
    G.flash_replace = True
    add_static_texts(G)
    if color is not None:
        # Ball.initColor: Color(base).setTransform(t), mc.color = t; the frame scripts of base (101), of the rolling
        # ball (124) and of 106 (its child b) set the same transform (Flash: it replaces the one of the placement)
        t = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[(color >> 16) - 255, ((color >> 8) & 0xFF) - 255, (color & 0xFF) - 255, 0])
        n = 0
        for sid, char in ((132, 101), (132, 124), (106, 104)):
            for ops in G.sprites[sid].frames:
                for kind, v in ops:
                    if kind == 'place' and v.get('char') == char:
                        v['cx'] = t
                        n += 1
        assert n == 3, n
    return G


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM = {
    # Mc.setColor(this / b, _parent.color): the colour is baked per ball colour (see new_swf); 117: no child b, no-op
    (101, 1): [], (106, 1): [], (117, 1): [], (124, 1): [],
    # partJet: if (first == null) { gotoAndPlay(random(_totalframes) + 1); first = true; }
    (165, 1): [['x', 'jetStart']],
    # partJet: _rotation = random(130) - 20; _xscale = 50 + random(60); _yscale = 50 + random(60)
    (165, 45): [['x', 'jetRnd']],
    (44, 49): [['x', 'rmSelf']],      # partJetAnim: removeMovieClip("")
    (47, 12): [['x', 'rmSelf']],      # queue: removeMovieClip("")
    (90, 52): [['x', 'rmSelf']],      # spark: removeMovieClip("")
}

G = new_swf()
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)     # the background bitmap at its native resolution
E = C.Exporter(G, SRC, '', CUSTOM)
E.bitmaps = (G1, bitmap_shapes())
# the ball of a score line: frame 1 (b.stop()), its colour set by the game (slotball0..6)
E.frames_for = {132: [1]}

E.export(172, 'bg')
# attached at 70 % (Game.initLevel): textures at that size
E.export(167, 'trou', res=0.7)
E.export(98, 'ship', code=('reacteur',))
E.export(47, 'queue')
E.export(90, 'spark')
E.export(169, 'lineseg')
# bar: gotoAndStop("carburant") (1) / gotoAndStop("puissance") (9)
E.export(164, 'bar', frames=[1, 9])
E.export(154, 'square', code=('s',))
# scoreSlot: gotoAndStop("1".."9"), bord.gotoAndStop(1..4), b: the ball (colour of the line)
E.export(150, 'scoreSlot', code=('bord', 'b'), frames=rng((1, 9)))

clips, pivots, area = dict(E.clips), dict(E.pivots), dict(E.area)

# the balls: Ball.update plays base (1-12, its loop), animMove / move (21-35), death / deathLoop (36-47) and roll
# (50-61: gotoAndPlay("roll"), then gotoAndStop(string(50 + frame)) with frame never initialized: "NaN", ignored by
# Flash, the roll loop plays); regarde (14-20) is never shown
BALL_FRAMES = rng((1, 12), (21, 47), (50, 61))
warnings = E.warnings
for i, col in enumerate(COLORS):
    Gi = new_swf(col)
    Ei = C.Exporter(Gi, SRC, 'k%d' % i, CUSTOM)
    Ei.export(132, 'ball%d' % i, frames=BALL_FRAMES)
    # (same resolution as the nested ball of scoreSlot: its matrix stays right after Clip.setDef)
    sres = [Ly for Ly in clips['scoreSlot']['layers'] if Ly.get('nm') == 'b'][0]['a']
    Ei.export(132, 'slotball%d' % i, frames=[1], res=clips[sres]['r'])
    clips.update(Ei.clips)
    pivots.update(Ei.pivots)
    area.update(Ei.area)
    warnings += Ei.warnings

# clips no root uses and their images
ROOTS = ['bg', 'trou', 'ship', 'queue', 'spark', 'lineseg', 'bar', 'square', 'scoreSlot'] + \
    ['ball%d' % i for i in range(7)] + ['slotball%d' % i for i in range(7)]
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [Ly['a'] for Ly in clips[nm]['layers'] if Ly['k'] == 2]
used = {Ly['a'] for nm in keep for Ly in clips[nm]['layers'] if Ly['k'] != 2}
for nm in [nm for nm in clips if nm not in keep]:
    for Ly in clips.pop(nm)['layers']:
        if Ly['k'] != 2 and Ly['a'] not in used:
            for a in (Ly['a'], Ly['a'] + 'W'):
                if a in area:
                    shutil.rmtree(os.path.join(SRC, a))
                    area.pop(a)
                    pivots.pop(a)
    print('  unused clip %s removed' % nm)

meta = {}


# ---------------------------------------------------------------- text fields written by the code
def font_layouts():
    """DefineFont2 / 3 id -> codes, ascent, descent, advances (em)"""
    out = {}
    for code, body in TAGS:
        if code not in (48, 75):
            continue
        em = 20480.0 if code == 75 else 1024.0
        fid, flags, lang, nl = struct.unpack_from('<HBBB', body, 0)
        q = 5 + nl
        ng = struct.unpack_from('<H', body, q)[0]; q += 2
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
        if not flags & 0x80:
            # (141: only used by static texts)
            continue
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        out[fid] = dict(ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


FONTS = font_layouts()
TX = swftext.all_edittexts(W + 'gfx.swf')


def glyph_path(fid, ch, size, x, y):
    """SVG path of a glyph of the TTF exported by FFDec (the SWF outlines), pen at (x, y) on the baseline"""
    from fontTools.ttLib import TTFont
    from fontTools.pens.svgPathPen import SVGPathPen
    from fontTools.pens.transformPen import TransformPen
    f = glob.glob(W + 'fonts_gfx/%d_*.ttf' % fid)[0]
    t = TTFont(f)
    gs = t.getGlyphSet()
    upm = t['head'].unitsPerEm
    pen = SVGPathPen(gs)
    gs[t.getBestCmap()[ord(ch)]].draw(TransformPen(pen, (size / upm, 0, 0, -size / upm, x, y)))
    return pen.getCommands()


def twips(v):
    return round(v * 20) / 20.0


def field_layout(tid, text):
    """glyph pens of a Flash text field (no autosize, one line) in the field's space: 2 px gutter, first baseline at
    top + 2 + ascent, left / center / right in the width without the gutters (twips)"""
    t = TX[tid]
    lay = FONTS[t['font']]
    size = t['height']
    x0, x1, y0, y1 = t['bounds']
    # (a character the embedded font does not hold is neither drawn nor advanced: font 138 has no space, "x " + carbu
    # shows "x7")
    text = ''.join(c for c in text if c in lay['adv'])
    adv = [twips(lay['adv'][c] * size) for c in text]
    width = sum(adv)
    inner = (x1 - x0) - 4 - t['leftMargin'] - t['rightMargin']
    if t['align'] == 'left':
        pen = x0 + 2 + t['leftMargin']
    elif t['align'] == 'center':
        pen = x0 + 2 + t['leftMargin'] + twips((inner - width) / 2)
    else:
        pen = x0 + 2 + t['leftMargin'] + inner - width
    base = twips(y0 + 2 + lay['ascent'] * size)
    out = []
    for c, a in zip(text, adv):
        out.append((c, pen, base))
        pen += a
    return out, size, t['color']


def check_layout_with_ffdec(tid):
    """the layout of the sample text of a field (FFDec SVG export) must give the same pens"""
    t = TX[tid]
    svg = open(W + 'txt_gfx/%d.svg' % tid).read()
    import re
    m = re.search(r'<g transform="matrix\(1.0, 0.0, 0.0, 1.0, ([-\d.]+), ([-\d.]+)\)">\s*<g transform="matrix\(1.0, 0.0, 0.0, 1.0, ([-\d.]+), ([-\d.]+)\)">', svg)
    gx, gy = float(m.group(1)) + float(m.group(3)), float(m.group(2)) + float(m.group(4))
    pens = [(float(a) + gx + t['bounds'][0], float(b) + gy + t['bounds'][2]) for a, b in
            re.findall(r'transform="matrix\([-\d.]+, 0.0, 0.0, [-\d.]+, ([-\d.]+), ([-\d.]+)\)" width', svg)]
    mine, _, _ = field_layout(tid, t['text'])
    # (a centred field: FFDec centres the text in the whole bounds then adds the 2 px gutter, 2 px right of the
    # middle; Flash (and Ruffle) centre it between the gutters: only the baseline and the advances are compared)
    dx = mine[0][1] - pens[0][0] if t['align'] != 'left' else 0
    for (c, x, y), (fx, fy) in zip(mine, pens):
        assert abs(x - dx - fx) < 0.051 and abs(y - fy) < 0.051, (tid, t['text'], mine, pens)
    print('  text field %d (%s): layout of "%s" = FFDec%s' % (tid, t['align'], t['text'], ' %+g' % dx if dx else ''))


def text_anim(name, parent_sid, tid, texts, res=1.0):
    """one picture per text of the field `tid` placed in parent_sid, in the parent's space (pivot: its origin)"""
    inst = R.Instance(G, parent_sid, ctrl={'__noactions__': True})
    ents = [e for e in inst.display.values() if e['char'] == tid]
    assert len(ents) == 1, (name, tid)
    m = ents[0]['matrix']
    assert m['b'] == 0 and m['c'] == 0, m
    svgs = []
    for s in texts:
        glyphs, size, color = field_layout(tid, s)
        paths = ''.join(glyph_path(TX[tid]['font'], c, size, x, y) for c, x, y in glyphs)
        svgs.append((paths, color))
    x0, x1, y0, y1 = TX[tid]['bounds']
    # canvas: the field's bounds in the parent (with a margin), on whole pixels of the output
    ox = math.floor(m['tx'] + m['a'] * x0) - 1
    oy = math.floor(m['ty'] + m['d'] * y0) - 1
    w = int(math.ceil(m['a'] * (x1 - x0))) + 3
    h = int(math.ceil(m['d'] * (y1 - y0))) + 3
    Z = 4
    imgs = []
    for paths, color in svgs:
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="%dpx" height="%dpx">'
               '<g transform="matrix(%r, 0, 0, %r, %r, %r)"><path fill="%s" d="%s"/></g></svg>') % (
            w, h, m['a'], m['d'], m['tx'] - ox, m['ty'] - oy, color, paths)
        im = rsvg(svg, Z)
        assert im.size == (w * Z, h * Z), (im.size, w, h)
        imgs.append(im.resize((int(w * K * res), int(h * K * res)), Image.LANCZOS))
    E.write_anim(name, imgs, (-ox * K * res, -oy * K * res))
    pivots[name] = E.pivots[name]
    area[name] = E.area[name]


for tid in (139, 140, 159):
    check_layout_with_ffdec(tid)
# Const.POINTS (pts.text = KKApi.val(Const.POINTS[id])): frame id + 1
POINTS = [1000, 700, 500, 300, 200, 100, 50]
text_anim('txtPts', 150, 139, [str(p) for p in POINTS])
# mult.text = "x " + carbu (1..7 when a score sheet is shown): frame carbu
text_anim('txtMult', 150, 140, ['x %d' % c for c in range(1, 8)])
# bar.fieldMulti.text = "x " + carbu (0..7): frame carbu + 1
text_anim('txtMulti', 164, 159, ['x %d' % c for c in range(0, 8)])

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
