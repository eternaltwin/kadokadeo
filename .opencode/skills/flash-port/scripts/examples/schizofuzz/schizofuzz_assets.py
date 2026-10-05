"""Builds the Schizo Fuzz graphics for KadoKadeo from the original SWF (_gfx.swf: the graphics of the released
game.swf, same shapes and timelines, readable instance names).

Every symbol the game attaches is exported as a Clip (timeline tables played by schizofuzz.Clip, see clipexport.py):
  - the hero (frames 1, 2, 3, 4, 6: the ones Game.hx can show) and its `sub` animations are flattened per frame; the
    tail `q` (frame chosen by the code), the shield `smc` (shown by the code) and the head `h` of the crash (turned by
    its frame script) stay separate clips, like the nested animations that keep playing on their own (blinks...);
  - the 6 items and their `sub` animations (played by the code when the hero hits them), the 6 icons of `next`,
    the particles, the aim, the altitude arrow (its text field is drawn by the game, Digits.hx);
  - the catapult (`startPlat.sub`) on the frames the code reaches: the idle loop 1-37, "back" and the charge
    43-123, "launch" (136) and the release 180-200;
  - the decor (bg_plan0..5, bgItem) is made of bitmaps: kept at their native resolution (drawn x2).
What the code measures on the display (_height of the decor planes, _width of the trees, bounds of the items read
by hitTest) is measured here on the SWF shapes and written in meta.json, with the layout of the altitude text.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: schizofuzz_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/schizofuzz holds _gfx.swf and its exports)
"""
import os, sys, json, shutil, math, re, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'schizofuzz', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + '_gfx.swf', W + 'shp4__gfx', Z=4)
Gp = R.SWF(W + '_gfx.swf', W + 'shp1__gfx', Z=1)     # bitmaps of the decor at their native resolution
Gb = R.SWF(W + '_gfx.swf', W + 'shp4__gfx', Z=4)     # untouched timelines, for the measures
for X in (G, Gp, Gb):
    X.flash_replace = True
    X.lighten = True      # the bush's highlight (sprite 62) is a 'lighten' layer
K = C.K


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as__gfx/)
CUSTOM_G = {
    (117, 1): [['x', 'hrot']],      # h of the crash: _rotation = -_global.hero._rotation
    (119, 18): [['x', 'pstop1']],   # end of the crash: _parent.gotoAndStop(1) (the hero flies again)
    (151, 15): [['x', 'pplay1']],   # slide: _parent.gotoAndPlay(1) (the hero's frame 1 stops it)
    (89, 9): [['x', 'spark']],      # acorn sparkle: a random place, smaller at each loop (c *= 0.75)
}

E = C.Exporter(G, SRC, '', CUSTOM_G)
E.clip_res = [0.5, 1.0, 1.5, 2.0]
# the glow of the hero (its sub) and of the arrow's head, the 'add' flash of the acorn: applied by Clip at run time
E.effects = True
E.strategy_for = {106: 'flat', 119: 'flat', 131: 'flat', 142: 'flat', 151: 'flat',
                  55: 'cut', 63: 'flat', 83: 'flat', 100: 'flat', 102: 'flat'}
E.code_for = {106: ('q', 'smc'), 119: ('smc', 'h'), 131: ('q', 'smc'), 142: ('q', 'smc'), 151: ('smc',),
              169: ()}

HERO_FRAMES = [1, 2, 3, 4, 6]
# startPlat.sub: idle loop 1-37, "back" (43) and the charge 43-123 (gotoAndStop), "launch" (136, played: one frame
# before Game sets 180-200 each frame of the flight)
PLATE_FRAMES = rng((1, 37), (43, 123), (136, 136), (180, 200))

E.export(153, 'hero', code=('sub',), frames=HERO_FRAMES)
E.export(103, 'item', code=('sub',))
E.export(94, 'next', strategy='flat')
E.export(162, 'part', strategy='flat')
E.export(165, 'aim')
E.export(170, 'arrow', code=('sub',))
E.export(193, 'plateSub', frames=PLATE_FRAMES)    # automatic: cut (8 Mpx flattened)
E.export(194, 'startPlat', code=('sub',))
# startPlat.sub: the catapult on the frames the code reaches only
_sub = [L for L in E.clips['startPlat']['layers'] if L.get('nm') == 'sub']
assert len(_sub) == 1 and _sub[0]['a'] == 'c193', E.clips['startPlat']
_sub[0]['a'] = 'plateSub'

# clips no longer used (the catapult on all its frames) and their images
ROOTS = ['hero', 'item', 'next', 'part', 'aim', 'arrow', 'startPlat']
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [L['a'] for L in E.clips[nm]['layers'] if L['k'] == 2]
used = {L['a'] for nm in keep for L in E.clips[nm]['layers'] if L['k'] != 2}
for nm in [nm for nm in E.clips if nm not in keep]:
    for L in E.clips.pop(nm)['layers']:
        if L['k'] != 2 and L['a'] not in used:
            for a in (L['a'], L['a'] + 'W'):
                if a in E.area:
                    shutil.rmtree(os.path.join(SRC, a))
                    E.area.pop(a)
                    E.pivots.pop(a)
    print('  unused clip %s removed' % nm)

Ep = C.Exporter(Gp, SRC, 'p', {})
Ep.export(Gp.sid('bg_plan5'), 'bg_plan5', strategy='flat', res=0.5)
Ep.export(201, 'bgItem', strategy='flat', res=0.5)

# bg_plan0..4: a shape of 1000 x h filled with the same 500 x h bitmap twice (fill matrices at x = 0 and 500, read in
# the FFDec SVG export): the bitmap once (its own pixels: the flat render of the shape is the same to 1/255), drawn
# twice by the clip
PLAN_BITMAPS = {0: (17, 16), 1: (14, 13), 2: (11, 10), 3: (8, 7), 4: (5, 4)}     # plane: (shape, bitmap)
for i, (shp, bmp) in PLAN_BITMAPS.items():
    svg = open(W + 'svg__gfx/%d.svg' % shp).read()
    fills = re.findall(r'patternTransform="matrix\(([^)]*)\)"', svg)
    assert fills == ['1.0, 0.0, 0.0, 1.0, 0.0, 0.0', '1.0, 0.0, 0.0, 1.0, 500.0, 0.0'], (shp, fills)
    im = Image.open(W + 'img__gfx/%d.png' % bmp).convert('RGBA')
    assert im.width == 500 and Gp.shapes[shp] == [0.0, 1000.0, 0.0, float(im.height)], (shp, im.size, Gp.shapes[shp])
    a = 'bgtile%d' % i
    Ep.write_anim(a, [im], (0, 0))
    Ep.clips['bg_plan%d' % i] = dict(n=1, r=0.5, layers=[dict(k=1, a=a, t=[1], m0=[0.0, 0.0, 1.0, 1.0, 0.0]),
                                                         dict(k=1, a=a, t=[1], m0=[500.0, 0.0, 1.0, 1.0, 0.0])])

clips, pivots, area = {}, {}, {}
for X in (E, Ep):
    for k in X.clips:
        assert k not in clips, k
    clips.update(X.clips)
    pivots.update(X.pivots)
    area.update(X.area)

meta = {}


# ---------------------------------------------------------------- values the code measures on the display
# Flash bounds: every shape rectangle through its full matrix (Renderer.bounds), in the coordinates of the clip
def bounds(sid, ctrl, M=R.IDENT):
    inst = R.Instance(Gb, sid, ctrl=dict(ctrl, __noactions__=True))
    rd = R.Renderer(Gb, 1)
    cmds = []
    rd.collect(inst, M, R.NOCX, set(), cmds)
    b = rd.bounds(cmds)
    return [round(b[0], 4), round(b[2], 4), round(b[1], 4), round(b[3], 4)]    # xMin xMax yMin yMax


def playing_sprites(sid, ctrl):
    """sprites with several frames reachable from the frame forced by ctrl (their frames change the bounds)"""
    out = set()
    inst = R.Instance(Gb, sid, ctrl=dict(ctrl, __noactions__=True))
    todo = [inst]
    while todo:
        i = todo.pop()
        for e in i.display.values():
            if e['inst'] is not None:
                if Gb.sprites[e['inst'].sid].nframes > 1:
                    out.add(e['inst'].sid)
                todo.append(e['inst'])
    return out


def steady_bounds(sid, ctrl):
    """bounds of a clip whose nested timelines play: the same whatever their frames (checked), else an error"""
    b0 = bounds(sid, ctrl)
    for s in playing_sprites(sid, ctrl):
        if s in ctrl:
            continue
        for f in range(1, Gb.sprites[s].nframes + 1):
            assert bounds(sid, dict(ctrl, **{s: f})) == b0, (sid, ctrl, s, f)
    return b0


# bg_plan0..4: _height (Game.new places them from the bottom of their area)
meta['bgHeight'] = [round(bounds(Gb.sid('bg_plan%d' % i), {})[3] - bounds(Gb.sid('bg_plan%d' % i), {})[2], 4)
                    for i in range(6)]
# bgItem: _width of each frame (placed at 300 + _width, removed beyond -_width)
meta['bgItemWidth'] = [round(b[1] - b[0], 4) for b in (bounds(201, {201: f}) for f in (1, 2, 3))]
# item: o.mc.hitTest(x, y) (Flash: the point in the bounds of the clip) on the items not hit yet: frame 1 + id, sub
# stopped on its first frame (shield: frame 2 when the hero already has one)
SUBS = {1: 55, 2: 63, 3: 65, 4: 83, 5: 100, 6: 102}
meta['itemBounds'] = [steady_bounds(103, {103: f, SUBS[f]: 1}) for f in range(1, 7)]
meta['shieldBounds2'] = steady_bounds(103, {103: 5, 100: 2})
# startPlat: _width (Game.checkObjects removes it beyond -_width), for each frame of its sub the code reaches (the
# nested animations on their first frame: the plate is off screen when it matters, nothing else reads it)
meta['plateWidth'] = [0.0] * 200
for f in PLATE_FRAMES:
    b = bounds(194, {193: f})
    meta['plateWidth'][f - 1] = round(b[1] - b[0], 4)
print('itemBounds', meta['itemBounds'], meta['shieldBounds2'])


# ---------------------------------------------------------------- arrow.txt: digits and "m" of the embedded Impact
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


GLYPHS = '0123456789m'


def glyph_anim(name, ttf, lay, size, color):
    """the glyphs 0-9 and m as images whose pivot is the pen position on the baseline"""
    SS = 4
    font = ImageFont.truetype(ttf, int(round(size * K * SS)))
    pad = 3
    w = int(math.ceil(max(lay['adv'][c] for c in GLYPHS) * size * K)) + 2 * pad + 4
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * K)) + 2 * pad + 2
    ox, oy = pad + 1, pad + int(math.ceil(lay['ascent'] * size * K))
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


TX = swftext.all_edittexts(W + '_gfx.swf')
FONTS = font_layouts(W + '_gfx.swf')
t = TX[168]
assert t['font'] == 167 and t['align'] == 'center' and not t['html'], t
info = glyph_anim('digits', W + 'fonts__gfx/167_impact.ttf', FONTS[167], t['height'], t['color'])
inst = R.Instance(Gb, 170, ctrl={'__noactions__': True})
m = [e for e in inst.display.values() if e['name'] == 'txt'][0]['matrix']
assert abs(m['a'] - 1) < 1e-3 and abs(m['d'] - 1) < 3e-3 and m['b'] == 0 and m['c'] == 0, m
# Flash text field: 2 px gutter, first baseline at top + 2 + ascent, centred in the width without the gutters
info.update(x=round(m['tx'] + t['bounds'][0] + 2, 3), w=round(t['bounds'][1] - t['bounds'][0] - 4, 3),
            base=round(m['ty'] + (t['bounds'][2] + 2 + info['ascent']) * m['d'], 3), sy=round(m['d'], 5))
meta['digits'] = info
print('digits', info)

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings + Ep.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
