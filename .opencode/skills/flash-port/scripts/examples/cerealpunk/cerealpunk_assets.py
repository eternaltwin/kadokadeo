"""Builds the Cereal Punk graphics for KadoKadeo from the original SWF (gfx.swf: the graphics of the released
cuistot.swf, same shapes and timelines, readable export and instance names).

Every symbol the game attaches is exported as a Clip (timeline tables played by cerealpunk.Clip, see clipexport.py):
  - the background (a 300 x 300 JPEG) and the cereals (40 x 40 bitmaps: one frame per kind, gold, bubble, stone,
    bonuses) are kept at their native resolution; the cereals have white silhouettes too (Const.setPercentColor
    whitens them when they explode);
  - the cook (`kanji`, drawn at 90 %: textures at 0.9), flattened per frame on the frames of its animations, with his
    hands `m.m` kept as nested clips: the code shows 0 to 3 cereals in them (`it0`..`it2`, the cereal clip; `sub`:
    the cracks of a stone);
  - the particles (rays, circles, pieces, stones, bubbles, bonus sparks) and the score that drops down (its text
    field is drawn by the game, Digits.hx).
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: cerealpunk_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/cerealpunk holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib, glob
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cerealpunk', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)       # vector shapes
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)      # the bitmaps (background, cereals) at their native resolution
for X in (G, G1):
    X.flash_replace = True
K = C.K


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


def bitmap_shapes():
    """ids of the shapes filled with a bitmap (FFDec SVG export: a pattern fill)"""
    return sorted(int(os.path.basename(f)[:-4]) for f in glob.glob(W + 'svg_gfx/*.svg') if 'pattern' in open(f).read())


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/ and as_cuistot/: the released cuistot.swf)
CUSTOM = {
    (7, 10): [['x', 'rmSelf']],       # partCircle2: removeMovieClip("")
    (39, 11): [['x', 'timer0']],      # partCircle: timer = 0 (Animator.main removes it at its next update)
    (32, 1): [['x', 'rndStop']],      # partStone: gotoAndStop(random(_totalframes) + 1)
    (48, 1): [['x', 'rndStop']],      # partPiece's grain: gotoAndStop(random(_totalframes) + 1)
    # fieldScore: compt = 20 / compt -= 1; if (compt > 0) gotoAndPlay(_currentframe - 1). In the released cuistot.swf the
    # obfuscator turned them into `"5t 9)" = 20` and `"5t 9)" = NaN` (P-code): the score never holds on frame 9
    (28, 8): [],
    (28, 10): [],
    (28, 16): [['x', 'rmSelf']],      # removeMovieClip("")
}

E = C.Exporter(G, SRC, '', CUSTOM)
E.bitmaps = (G1, bitmap_shapes())
# the cook's hands: m (113) holds m (112), whose cereals it0..it2 the code shows (Hero.updateHands)
E.code_for = {113: ('m',), 112: ('it0', 'it1', 'it2')}
# the bitmaps: one CUT layer each (pictures at their native resolution), also inside the hands
E.strategy_for = {84: 'cut', 79: 'cut', 124: 'cut'}

# legume (84): frame id + 1: the 5 kinds (1-5), gold (10-14), bubble (21), stone (22, its cracks `sub`), bonuses (23, 24)
LEG_FRAMES = rng((1, 5), (10, 14), (21, 24))
E.frames_for = {84: LEG_FRAMES}
# the cook: Hero.WAIT / WAIT_LOCK (1), JUMP (8-13), END_JUMP (14-24), TAKE (27-31), END_TAKE (32-39), PUT (42-44),
# END_PUT (45-58), shown by gotoAndStop only
HERO_FRAMES = rng((1, 1), (8, 24), (27, 39), (42, 58))

E.export(124, 'bg')
E.export(84, 'legume', strategy='cut', frames=LEG_FRAMES, white=True)
# drawn at mc._xscale = 90: textures at that size
E.export(114, 'kanji', strategy='flat', code=('m',), frames=HERO_FRAMES, res=0.9)
E.export(28, 'fieldScore', code=('sc',))
for sid, name in ((4, 'partBonusDie'), (7, 'partCircle2'), (17, 'partRay'), (21, 'partBonus2'), (24, 'partBonus'),
                  (32, 'partStone'), (34, 'partBubble'), (39, 'partCircle'), (50, 'partPiece')):
    E.export(sid, name)

# clips no root uses and their images
ROOTS = ['bg', 'legume', 'kanji', 'fieldScore', 'partBonusDie', 'partCircle2', 'partRay', 'partBonus2', 'partBonus',
         'partStone', 'partBubble', 'partCircle', 'partPiece']
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [Ly['a'] for Ly in E.clips[nm]['layers'] if Ly['k'] == 2]
used = {Ly['a'] for nm in keep for Ly in E.clips[nm]['layers'] if Ly['k'] != 2}
for nm in [nm for nm in E.clips if nm not in keep]:
    for Ly in E.clips.pop(nm)['layers']:
        if Ly['k'] != 2 and Ly['a'] not in used:
            for a in (Ly['a'], Ly['a'] + 'W'):
                if a in E.area:
                    shutil.rmtree(os.path.join(SRC, a))
                    E.area.pop(a)
                    E.pivots.pop(a)
    print('  unused clip %s removed' % nm)

clips, pivots, area = dict(E.clips), dict(E.pivots), dict(E.area)
meta = {}


# ---------------------------------------------------------------- fieldScore: the score text (Impact 18, right aligned)
def font_layouts(path):
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
        out[fid] = dict(codes=codes, ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


GLYPHS = '0123456789'


def glyph_anim(name, ttf, lay, size, color, res):
    """the digits as images whose pivot is the pen position on the baseline, at res (texture px = K * res)"""
    SS = 4
    s = K * res
    font = ImageFont.truetype(ttf, int(round(size * s * SS)))
    pad = 3
    w = int(math.ceil(max(lay['adv'][c] for c in GLYPHS) * size * s)) + 2 * pad + 4
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * s)) + 2 * pad + 2
    ox, oy = pad + 1, pad + int(math.ceil(lay['ascent'] * size * s))
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    rgb = tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))
    a = 0
    for i, ch in enumerate(GLYPHS):
        big = Image.new('L', (w * SS, h * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.LANCZOS)
        g = Image.new('RGBA', (w, h), rgb + (0,))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
        a += w * h
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    area[name] = a
    return dict(adv=[round(lay['adv'][c] * size, 4) for c in GLYPHS], ascent=round(lay['ascent'] * size, 4))


TX = swftext.all_edittexts(W + 'gfx.swf')
FONTS = font_layouts(W + 'gfx.swf')
t = TX[26]
assert t['font'] == 25 and t['align'] == 'right' and not t['html'] and t['variable'] == '_parent.score', t
assert t['leftMargin'] == 0 and t['rightMargin'] == 0, t
# the picture of `sc` (the text field alone) in fieldScore
sc = [Ly for Ly in clips['fieldScore']['layers'] if Ly.get('nm') == 'sc']
assert len(sc) == 1 and sc[0]['k'] == 1, clips['fieldScore']
DIG_RES = clips['fieldScore']['r']
info = glyph_anim('digits', W + 'fonts_gfx/25_impact.ttf', FONTS[25], t['height'], t['color'], DIG_RES)
inst = R.Instance(G, 27, ctrl={'__noactions__': True})
m = [e for e in inst.display.values() if e['char'] == 26][0]['matrix']
assert m['a'] == 1 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0, m
# Flash text field: 2 px gutter, first baseline at top + 2 + ascent, right aligned in the width without the gutters
info.update(right=round(m['tx'] + t['bounds'][1] - 2, 3), base=round(m['ty'] + t['bounds'][2] + 2 + info['ascent'], 3),
            res=DIG_RES)
meta['digits'] = info
print('digits', info)

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
