"""Builds the Cosmo Crash graphics for KadoKadeo from the original SWF (gfx.swf: the graphics of the released game.swf,
same shapes and timelines, readable instance names).

Every symbol the game attaches is exported as a Clip (timeline tables played by cosmocrash.Clip, see clipexport.py):
  - the hero (white silhouettes too: the code tints it white at its arrival and red when the fuel is low), its two
    flames `_reac0` / `_reac1` (shown by the code) stay separate clips;
  - the colonists (mcFolk) in 4 colours: the original colours parts of them by code (Col.setColor: multiply 100 % +
    offset colour - 255, not a tint) from the first frame script of their nested clips (`_parent._colorMe(smc)`) and
    from the frame scripts of their "_hello" / "_face" frames (`_colorMe(smc)`). Only the folks and the passenger
    icons (mcCosmo) have a `_colorMe`, so the colours are baked: one copy of mcFolk / mcCosmo per colour whose
    scripted children colour their `smc`. Folk.applySkin (offset colour - 340) on the `smc` of "_hello" / "_face"
    swaps that nested clip for a variant baked at -340 (Data.VAR340);
  - the platform (its parts placed and stretched by the code), its ramp, the shuttle in it and the colonist that
    walks in (`smc`, darkened by the ramp's timeline), the level shown on the shuttles (sprite 144 goes to
    _parent._parent._lvl + 1, set by the code);
  - the vehicles (body, back, canon, wheels: placed by the code), shots, explosion, shock wave, sparks, dust, the
    pieces of the hero, the score that rises (its text field is drawn by the game, Digits.hx), the gyroscope;
  - the decor of the horizon (mcDecor, 41 frames tinted by their timeline), the sky / ground gradients, the stars.
The level bitmap (bmpLevel: rocks and dirt drawn at run time from the fixed generator mt.Rand(0)) is drawn here
(cosmocrash_level.py) and cut in tiles; the background (mcBg drawn into a 10 x 10 bitmap scaled 3000 %, not smoothed)
is written as its 100 pixels. What the code measures on the display (_width of the decor, positions of nested clips
read by Geom.getParentCoord) is measured on the SWF and written in meta.json, with the layout of the score text.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: cosmocrash_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/cosmocrash holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD
import cosmocrash_level as L

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cosmocrash', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
Gb = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)     # untouched timelines, for the measures
for X in (G, Gb):
    X.flash_replace = True
    # the fuel gauge (gyro.vector): half discs masking the white halves, inside the ring of shape 67 masking them
    X.nested_masks = True
K = C.K


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


# ---------------------------------------------------------------- colours of the colonists
COLORS = [0xFFFFFF, 0x66FF00, 0x8888FF, 0xFF44CC]      # Folk.new: [type]


def set_color(col, dec):
    """Col.setColor(mc, col, dec): multiply 100 %, offset (channel + dec) (Std.int)"""
    return dict(mult=[1.0, 1.0, 1.0, 1.0], add=[((col >> 16) & 0xFF) + dec, ((col >> 8) & 0xFF) + dec, (col & 0xFF) + dec, 0])


# children of mcFolk / mcCosmo whose first frame script is `_parent._colorMe(smc)` (their parent has a _colorMe)
COLOR_ME = (33, 111, 114, 120, 123, 130)
FOLK, COSMO = 137, 36


def clone(sid, nid, patch):
    sd = G.sprites[sid]
    nd = R.SpriteDef(nid, sd.nframes)
    nd.labels = dict(sd.labels)
    nd.actions = dict(sd.actions)
    for f, ops in enumerate(sd.frames, 1):
        nd.frames.append([(k, patch(f, dict(v)) if k == 'place' else v) for k, v in ops])
    G.sprites[nid] = nd
    return nid


def colour_clones(k):
    """mcFolk and mcCosmo of colour k: their scripted children colour their smc (-255), and mcFolk's own scripts of
    "_hello" / "_face" colour its smc (-255)"""
    cx = set_color(COLORS[k], -255)
    kids = {}
    for s in COLOR_ME:
        def p(f, v, cx=cx):
            if v.get('name') == 'smc':
                v['cx'] = cx
            return v
        kids[s] = clone(s, k * 10000 + s, p)

    def pf(f, v):
        if v.get('char') in kids:
            v['char'] = kids[v['char']]
        if f in (55, 62) and v.get('name') == 'smc':
            v['cx'] = cx
        return v
    return clone(FOLK, k * 10000 + FOLK, pf), clone(COSMO, k * 10000 + COSMO, pf), list(kids.values())


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/; the released game.swf for the ramp)
CUSTOM = {
    (FOLK, 55): [['x', 'colorMe']],     # _colorMe(smc)
    (FOLK, 62): [['x', 'colorMe']],
    (144, 1): [['x', 'lvl']],           # gotoAndStop(_parent._parent._lvl + 1)
    (175, 74): [['x', 'launch']],       # _parent._launch()
    # compt = 50 / if (compt-- > 0) gotoAndPlay(_currentframe - 1): in the released game.swf the obfuscator turned
    # these into `"5t 9)" = 50` and `"5t 9)" = NaN` (P-code): the ramp never holds on frame 77
    (175, 76): [],
    (175, 78): [],
    (54, 33): [['x', 'rmSelf']],        # mcExplosion: removeMovieClip()
    (57, 16): [['x', 'rmSelf']],        # mcOnde
    (50, 1): [['x', 'rot5']],           # _rotation += 5 (the second shot turns)
}
for s in COLOR_ME:
    CUSTOM[(s, 1)] = []                 # _parent._colorMe(smc): baked in the colour copies
CLONES = {}
for k in (1, 2, 3):
    f, c, kids = colour_clones(k)
    CLONES[k] = (f, c)
    for s in kids:
        CUSTOM[(s, 1)] = []
    CUSTOM[(f, 55)] = CUSTOM[(FOLK, 55)]
    CUSTOM[(f, 62)] = CUSTOM[(FOLK, 62)]

class Exporter(C.Exporter):
    # one frame sprites kept as nested clips, not pictures of their parent: the smc of "_face" (131; Folk.applySkin
    # swaps it for its -340 variant) and gyro.stab (66: the code scales stab.smc)
    def alive(self, sid, ctrl):
        return sid in (131, 66) or super().alive(sid, ctrl)


E = Exporter(G, SRC, '', CUSTOM)
E.strategy_for = {FOLK: 'flat'}       # the colonist in the ramp
E.clip_res = [0.5, 1.0, 1.5, 2.0]
E.code_for = {
    175: ('shuttle', 'digit', 'smc'),   # mcRampe
    28: ('smc',),                       # mcCanon: the flash of the shot
    66: ('smc',),                       # gyro.stab.smc: _yscale = speed
}
for k in (1, 2, 3):
    E.code_for[CLONES[k][0]] = ('smc',)
E.code_for[FOLK] = ('smc',)

# mcFolk: walk 1-16, "jump" 20, "_jump2" 25-41 (played, also from 25-34 after a crash), "_seat" 46, "_hello" 55,
# "_face" 62, "_jump" 67-94 (played)
FOLK_FRAMES = rng((1, 16), (20, 20), (25, 41), (46, 46), (55, 55), (62, 62), (67, 94))

E.export(81, 'mcHero', strategy='flat', code=('_reac0', '_reac1'), frames=[1], white=True)
E.export(93, 'partHero', code=('smc',), frames=rng((1, 12)))
E.export(FOLK, 'mcFolk', strategy='flat', frames=FOLK_FRAMES)
for k in (1, 2, 3):
    E.export(CLONES[k][0], 'mcFolk%d' % k, strategy='flat', frames=FOLK_FRAMES)
E.export(COSMO, 'mcCosmo', strategy='flat', res=2.0)
for k in (1, 2, 3):
    E.export(CLONES[k][1], 'mcCosmo%d' % k, strategy='flat', res=2.0)
E.export(185, 'mcPlat', code=('shade', 'rampe', 'pil0', 'pil1', 'base', 'left', 'right'))
E.export(152, 'mcShuttle', frames=[14])
E.export(24, 'mcJeep', strategy='flat', frames=[1, 2, 3, 4])
E.export(28, 'mcCanon')
E.export(30, 'mcWheel')
E.export(51, 'mcShot')
E.export(54, 'mcExplosion')
E.export(57, 'mcOnde')
E.export(60, 'partSpark', code=('smc',))
E.export(8, 'partDust', res=2.0)
E.export(40, 'fxScore', code=('smc',))
E.export(72, 'mcGyro', code=('stab', 'vector', 'inf'))
# gyro.stab.smc (a 22 x 22 square, _yscale = speed set by the code) is masked by the red disc of stab (shape 63,
# clipDepth): the band it shows, the square cut by the disc, for each half height of 0 to 11 Flash pixels in steps of a
# texture pixel (anim 'gyroBand', frame 1: nothing, frame 23: the whole disc), drawn as stab.smc by the game (no mask at
# run time)
BAND_STEPS = 22
_st = R.Instance(G, 66, ctrl={'__noactions__': True})
assert [e['char'] for e in _st.display.values() if e['clip'] is not None] == [63], _st.display
_band = []
for h in range(BAND_STEPS + 1):
    for e in _st.display.values():
        if e['name'] == 'smc':
            e['matrix'] = dict(R.IDENT, d=h / float(BAND_STEPS))
    cm = []
    R.Renderer(G, K).collect(_st, R.IDENT, R.NOCX, set(), cm)
    _band.append([c for c in cm if c[0] == 'mask'])
_imgs, _reg = E.render(_band, K * E.clips['c66']['r'])
E.write_anim('gyroBand', _imgs, _reg)
_smc = [Ly for Ly in E.clips['c66']['layers'] if Ly.get('nm') == 'smc']
assert len(_smc) == 1 and _smc[0]['k'] == 1 and _smc[0]['m0'] == [0.0, 0.0, 1.0, 1.0, 0.0], E.clips['c66']
_old = _smc[0]['a']
_smc[0]['a'] = 'gyroBand'
_smc[0]['t'] = [BAND_STEPS + 1]
if not any(Ly['a'] == _old for c in E.clips.values() for Ly in c['layers']):
    shutil.rmtree(os.path.join(SRC, _old))
    E.area.pop(_old)
    E.pivots.pop(_old)
E.export(42, 'mcStar')
# mcDecor: Game.initHor shows frame i + 1 with its smc on frame i + 1 (i < 40), coloured by the timeline: one picture
# each, colour baked ('decor<i>')
for i in range(40):
    E.export(105, 'decor%d' % i, strategy='flat', ctrl={105: i + 1, 104: i + 1})
E.export(204, 'mcHor', code=('smc',))

# Folk.applySkin: Col.setColor(smc, colour, -340) on the smc of "_hello" (127) / "_face" (131): variants of every
# nested clip exported for them, for the colours that can reach it (the baked -255 colour of the copy; uncoloured: the
# white folks and the colonist in the ramp, which has no _colorMe, any colour)
VAR340 = {}
for vkey, cname in list(E.variants.items()):
    sid, ctrl, strategy, code, frames, cxk, res, cut, white, stack = vkey
    if sid not in (127, 131):
        continue
    assert not ctrl and not frames and not cut and not stack, vkey
    ks = [k for k in range(4) if C.cx_key(set_color(COLORS[k], -255)) == cxk]
    if cxk == C.cx_key(R.NOCX):
        # the white folks (k = 0), or the colonist in the ramp (exported with white silhouettes: the ramp darkens it),
        # which only shows "_face"
        ks = [0, 1, 2, 3] if white else [0]
        if white and sid == 127:
            continue
    assert ks, (cname, cxk)
    VAR340[cname] = {}
    for k in ks:
        VAR340[cname][str(k)] = E.export(sid, name='%s_k%d' % (cname, k), strategy=strategy, code=code, cx=set_color(COLORS[k], -340),
                                         res=res, white=white)
print('VAR340', VAR340)

# clips no root uses and their images
ROOTS = ['mcHero', 'partHero', 'mcFolk', 'mcFolk1', 'mcFolk2', 'mcFolk3', 'mcCosmo', 'mcCosmo1', 'mcCosmo2', 'mcCosmo3',
         'mcPlat', 'mcShuttle', 'mcJeep', 'mcCanon', 'mcWheel', 'mcShot', 'mcExplosion', 'mcOnde', 'partSpark', 'partDust',
         'fxScore', 'mcGyro', 'mcStar', 'mcHor'] + ['decor%d' % i for i in range(40)] + [n for v in VAR340.values() for n in v.values()]
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
meta = {'var340': VAR340}


# ---------------------------------------------------------------- level: ground tiles
top, plats, ops = L.level()
ground = L.render(G, ops)
alpha = np.asarray(ground)[..., 3]
rows = np.where(alpha.max(axis=1) > 0)[0]
gy0 = int(rows.min()) // K                       # first Flash pixel row drawn
TILE = 250
tiles = []
for i in range(L.LW // TILE):
    tiles.append(ground.crop((i * TILE * K, gy0 * K, (i + 1) * TILE * K, L.LH * K)))
E.write_anim('ground', tiles, (0, 0))
pivots['ground'] = E.pivots['ground']
area['ground'] = E.area['ground']
meta['ground'] = dict(y0=gy0, tile=TILE, n=len(tiles))
meta['level'] = dict(top=top, plats=[list(p) for p in plats])

# ---------------------------------------------------------------- background: mcBg drawn into a 10 x 10 bitmap
# BitmapData.draw(mcBg) at 1 px per Flash pixel: its one shape (205) is a linear gradient, which the Flash player
# samples at the top left corner of each pixel (the bands of the released game: #07134f on the first 30 px of the
# sky, then about 10 more blue per band); computed from the gradient of the FFDec SVG export
def svg_linear_gradient(path):
    import re
    svg = open(path).read()
    m = [float(v) for v in re.search(r'gradientTransform="matrix\(([^)]*)\)"', svg).group(1).split(',')]
    x1 = float(re.search(r'x1="([^"]*)"', svg).group(1))
    x2 = float(re.search(r'x2="([^"]*)"', svg).group(1))
    stops = [(float(o), int(c[1:], 16)) for o, c in re.findall(r'<stop offset="([^"]*)" stop-color="([^"]*)"', svg)]
    a, b, c, d, tx, ty = m
    det = a * d - b * c

    def colour(x, y):
        # inverse of the gradient matrix: position along the gradient axis
        u = (d * (x - tx) - c * (y - ty)) / det
        t = min(1.0, max(0.0, (u - x1) / (x2 - x1)))
        for (o0, c0), (o1, c1) in zip(stops, stops[1:]):
            if t <= o1:
                k = 0.0 if o1 == o0 else (t - o0) / (o1 - o0)
                return tuple(int(round(((c0 >> s) & 0xFF) * (1 - k) + ((c1 >> s) & 0xFF) * k)) for s in (16, 8, 0))
        return tuple((stops[-1][1] >> s) & 0xFF for s in (16, 8, 0))
    return colour


assert Gb.sprites[Gb.sid('mcBg')].frames[0][0][1]['char'] == 205
grad = svg_linear_gradient(W + 'svg_gfx/205.svg')
meta['bg'] = [(r << 16) | (g << 8) | b for (r, g, b) in (grad(x, y) for y in range(10) for x in range(10))]


# ---------------------------------------------------------------- values the code reads on the display
def bounds(sid, ctrl, M=R.IDENT):
    inst = R.Instance(Gb, sid, ctrl=dict(ctrl, __noactions__=True))
    rd = R.Renderer(Gb, 1)
    cmds = []
    rd.collect(inst, M, R.NOCX, set(), cmds)
    b = rd.bounds(cmds)
    return [round(b[0], 4), round(b[2], 4), round(b[1], 4), round(b[3], 4)]    # xMin xMax yMin yMax


def child(sid, frame, name):
    inst = R.Instance(Gb, sid, ctrl={'__noactions__': True, sid: frame})
    es = [e for e in inst.display.values() if e['name'] == name]
    assert len(es) == 1, (sid, frame, name)
    return es[0]['matrix']


def flash_rot(m):
    return math.degrees(math.atan2(m['b'], m['a']))


# Game.initHor / display: mc._width of mcDecor on frame i + 1 (its smc on frame i + 1)
meta['decorWidth'] = []
for i in range(40):
    b = bounds(105, {105: i + 1, 104: i + 1})
    meta['decorWidth'].append(round(b[1] - b[0], 4))
# Plat.launch: Geom.getParentCoord(skin.rampe.shuttle, skin) on frame 74 of the ramp (its _parent._launch())
m = child(175, 74, 'shuttle')
mr = child(185, 1, 'rampe')
assert abs(mr['a'] - 1) < 1e-9 and mr['b'] == 0 and mr['c'] == 0 and mr['tx'] == 0 and mr['ty'] == 0, mr
meta['launch'] = dict(x=m['tx'], y=m['ty'], rot=flash_rot(m), rampeYScale=mr['d'] * 100)
# Vehicule.shoot: Geom.getParentCoord(canon.smc, root)
m = child(28, 1, 'smc')
meta['canonSmc'] = [m['tx'], m['ty']]
# Hero.crash: Geom.getParentCoord(mc.smc, mc) of partHero on frames 1..12
meta['partHeroSmc'] = []
for f in range(1, 13):
    m = child(93, f, 'smc')
    meta['partHeroSmc'].append([m['tx'], m['ty']])
print('launch', meta['launch'], 'canon', meta['canonSmc'])


# ---------------------------------------------------------------- fxScore: the score text (ProggySmallTT, centred)
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
t = TX[38]
assert t['font'] == 37 and t['align'] == 'center' and not t['html'] and t['variable'] == '_parent._sc', t
# the text is scaled by the timeline of fxScore up to 1.15: glyphs at 1.25
DIG_RES = 1.25
info = glyph_anim('digits', W + 'fonts_gfx/37_ProggySmallTT.ttf', FONTS[37], t['height'], t['color'], DIG_RES)
inst = R.Instance(Gb, 39, ctrl={'__noactions__': True})
m = [e for e in inst.display.values() if e['char'] == 38][0]['matrix']
assert m['a'] == 1 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0, m
# Flash text field: 2 px gutter, first baseline at top + 2 + ascent, centred in the width without the gutters
info.update(x=round(m['tx'] + t['bounds'][0] + 2, 3), w=round(t['bounds'][1] - t['bounds'][0] - 4, 3),
            base=round(m['ty'] + t['bounds'][2] + 2 + info['ascent'], 3), res=DIG_RES)
meta['digits'] = info
print('digits', info)

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
