"""Builds the K-Slash graphics for KadoKadeo from the original SWF (gfx.swf, decor.swf).

Every symbol used by the game is exported as a Clip (timeline tables played by kslash.Clip, see clipexport.py)
with the fewest textures possible:
  - characters (hero, soldiers, tanker, flyer) are flattened per frame at x2 for the exact Flash rendering, the
    nested animations that keep playing on their own (scarf, headband, ball, smoke, wings, slash...) stay
    separate clips; the explosion of the monsters is one shared white sequence tinted at run time;
  - the 3 soldiers are 3 variants of mcMonster (skin, death pieces and spikes of their level baked);
  - the afterimages of the super hero (mcShade) are white silhouettes coloured by the code like the timeline of
    mcShade did (its colour transform on the purple silhouette gives one flat colour per frame);
  - the decor and the platforms are bitmaps: kept at their native resolution (displayed x2), each with the matrix
    of its bitmap fill (no resampling).
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: kslash_assets.py <out dir>
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

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'kslash', '')   # SWF + FFDec exports (see rebuild_assets.sh)
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

Gg = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
Gp = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)      # bitmaps of the platforms at their native resolution
for G in (Gg, Gp):
    G.flash_replace = True


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


# frame scripts that are not plain playhead moves
CUSTOM_G = {
    (40, 1): [['x', 'kflip']],            # k._xscale = _parent._xscale (headband letter never mirrored)
    (40, 2): [['g', 1, 1]],               # gotoAndPlay(_currentframe - 1)
    (63, 1): [['x', 'kflip']],
    (63, 2): [['g', 1, 1]],
    (222, 1): [['x', 'rot0']],            # _rotation = 360
    (222, 2): [['x', 'shrink6']],         # _xscale -= 6; _yscale = _xscale
    (225, 1): [['r', 2, 6]],              # partSpark: gotoAndPlay(random(_totalframes - 1) + 2)
    (3, 9): [['x', 'sparkle']],           # twinkles jump around the supa star
    (4, 60): [],                          # _parent.removeMovieClip(): its parent is placed on a timeline, Flash ignores it
    (376, 1): [['x', 'skin']],            # gotoAndStop(_parent.b1._currentframe): death pieces in the skin colour
    (212, 19): [['x', 't0']],             # partSmoke: t = 0 (the particle dies)
    (385, 126): [['x', 'rmSelf']],        # monster death: removeMovieClip()
    (269, 79): [['x', 'rmSelf']],
    (290, 50): [['x', 'rmSelf']],
}

Eg = C.Exporter(Gg, SRC, '', CUSTOM_G)
Eg.clip_res = [0.5, 1.0, 1.5, 2.0]   # nested clips shown bigger than their symbol (spark rings) stay sharp
Eg.code_for = {40: ('k',), 63: ('k',), 29: ('blade',)}
Eg.strategy_for = {331: 'cut'}
# explosion of the monsters (frame by frame, drawn in a flat colour by every monster): one white sequence
FAMILY = [243, 245, 247, 249, 251, 253, 255] + list(range(257, 269))
Eg.families = [FAMILY]
Eg.family_res = 0.5
Ep = C.Exporter(Gp, SRC, 'p', {})

# frames reachable by the game (labels played by the code, until the stop / loop of each animation)
HERO_FRAMES = rng((1, 26), (29, 36), (60, 62), (71, 113), (117, 118), (128, 140), (142, 145))
MON_FRAMES = rng((1, 72), (75, 95), (99, 126), (128, 150))
TANK_FRAMES = rng((1, 21), (24, 41), (59, 65), (70, 79))
FLY_FRAMES = rng((1, 23), (31, 50))

# ---------------------------------------------------------------- characters
Eg.export(73, 'mcHero', strategy='flat', code=('bfx', 'kunai'), frames=HERO_FRAMES)
# Soldier.setLevel: b1 (skin, a tint per level) and noSpikes (b3, b4, b5) are driven by the code, the death pieces
# take the frame of b1: one clip for the 3 levels
Eg.export(385, 'mcMonster', strategy='flat', code=('b1', 'b3', 'b4', 'b5'), frames=MON_FRAMES, cut_depths=(14, 18, 20))
Eg.export(269, 'mcTanker', strategy='flat', frames=TANK_FRAMES, cut_depths=(18, 20))
Eg.export(290, 'mcFlyer', strategy='flat', frames=FLY_FRAMES, cut_depths=(4, 6, 13, 15))

# afterimage: the silhouette of every hero frame (shade.gotoAndStop(hero._currentframe)), white
SHADE_FRAMES = sorted({min(f, 143) for f in HERO_FRAMES})
Eg.export(182, 'mcShadeBody', strategy='flat', frames=SHADE_FRAMES, cx=C.WHITE)

# ---------------------------------------------------------------- shots, bonus, particles, interface
Eg.export(311, 'mcNinjaShot')
Eg.export(214, 'mcKunai', strategy='flat')
Eg.export(330, 'bonus', strategy='flat')
Eg.export(193, 'mcIcon', strategy='flat')
for sid, name in ((186, 'partLight'), (212, 'partSmoke'), (217, 'partDust'), (219, 'partCircle'), (225, 'partSpark')):
    Eg.export(sid, name)
Eg.export(294, 'inter', strategy='flat')

# ---------------------------------------------------------------- platforms (bitmaps: native resolution)
Ep.export(390, 'platText1', strategy='flat', res=0.5)
Ep.export(397, 'platText2', strategy='flat', res=0.5)
Ep.export(394, 'platCorner1', strategy='flat', res=0.5)
Ep.export(401, 'platCorner2', strategy='flat', res=0.5)

# gems (bonus 1 to 3): the sparkling gem under a colour transform with negative offsets (no tint + added colour can
# do it): one variant of the gem per frame, its colour baked
L0 = Eg.clips['bonus']['layers'][0]
assert L0['a'] == 'c317' and L0['k'] == 2
gems = []
for f in (1, 2, 3):
    inst = R.Instance(Gg, 330, ctrl={330: f, '__noactions__': True})
    name = Eg.export(317, 'gem%d' % f, cx=inst.display[1]['cx'], res=Eg.clips['c317']['r'])
    gems.append(dict(k=2, a=name, p=[1 if i == f - 1 else 0 for i in range(Eg.clips['bonus']['n'])], m0=L0['m0']))
Eg.clips['bonus']['layers'] = gems + Eg.clips['bonus']['layers'][1:]
# clips no longer used (the tinted gem) and their images
ROOTS = ['mcHero', 'mcMonster', 'mcTanker', 'mcFlyer', 'mcShadeBody', 'mcNinjaShot', 'mcKunai', 'bonus', 'mcIcon', 'partLight',
         'partSmoke', 'partDust', 'partCircle', 'partSpark', 'inter']
for E in (Eg,):
    keep, todo = set(), list(ROOTS)
    while todo:
        n = todo.pop()
        if n in keep:
            continue
        keep.add(n)
        todo += [L['a'] for L in E.clips[n]['layers'] if L['k'] == 2]
    used = {L['a'] for n in keep for L in E.clips[n]['layers'] if L['k'] != 2}
    for n in [n for n in E.clips if n not in keep]:
        for L in E.clips.pop(n)['layers']:
            if L['k'] != 2 and L['a'] not in used:
                for a in (L['a'], L['a'] + 'W'):
                    if a in E.area:
                        shutil.rmtree(os.path.join(SRC, a))
                        E.area.pop(a)
                        E.pivots.pop(a)
        print('  unused clip %s removed' % n)

clips = {}
pivots = {}
area = {}
for E in (Eg, Ep):
    for k in E.clips:
        assert k not in clips, k
    clips.update(E.clips)
    pivots.update(E.pivots)
    area.update(E.area)

meta = {}

# ---------------------------------------------------------------- mcShade
# timeline of mcShade: the purple silhouette (sprite 182) under a colour transform tween + alpha; every pixel of
# the silhouette has the same colour: the result is a flat colour per frame (clamped like Flash), drawn as a tint
sil = Image.open(W + 'shp4_gfx/74.png').convert('RGBA')
a = np.asarray(sil)
px = a[a[..., 3] == 255][:, :3]
vals, counts = np.unique(px.reshape(-1, 3), axis=0, return_counts=True)
P = vals[np.argmax(counts)].tolist()
print('shade colour', P, 'share %.3f' % (counts.max() / counts.sum()))
shade_rows = []
for f in range(1, 30):
    inst = R.Instance(Gg, 183, ctrl={183: f, '__noactions__': True})
    e = inst.display[1]
    m, ad = e['cx']['mult'], e['cx']['add']
    col = [max(0, min(255, int(P[i] * m[i] + ad[i]))) for i in range(3)]
    mat = e['matrix']
    shade_rows.append(dict(col=(col[0] << 16) | (col[1] << 8) | col[2], al=round(m[3], 5), x=mat['tx'], y=mat['ty']))
assert all(r['x'] == shade_rows[0]['x'] and r['y'] == shade_rows[0]['y'] for r in shade_rows)
body_r = clips['mcShadeBody']['r']
clips['mcShade'] = dict(
    n=30, r=1.0,
    layers=[dict(k=2, a='mcShadeBody', nm='shade', p=[1] * 29 + [0],
                 m0=[round(shade_rows[0]['x'] * C.K, 2), round(shade_rows[0]['y'] * C.K, 2), round(1.0 / body_r, 5), round(1.0 / body_r, 5), 0],
                 al=[r['al'] for r in shade_rows] + [0], tns=[r['col'] for r in shade_rows] + [0xFFFFFF])],
    acts={'30': [['x', 'rmSelf']]})

# ---------------------------------------------------------------- decor (bitmaps of decor.swf, native resolution)
# bitmap fills of the shapes (read in the SVG export of FFDec): [image, a, b, c, d, tx, ty]
DECOR_BITMAPS = {1: 'img_decor/1.png', 6: 'img_decor/6.png', 8: 'img_decor/8.png', 9: 'img_decor/9.png',
                 10: 'img_decor/10.png', 12: 'img_decor/12.png', 15: 'img_decor/15.jpg', 17: 'img_decor/17.jpg'}


def svg_fills(sid):
    s = open(W + 'svg_decor/%d.svg' % sid, encoding='utf-8').read()
    g = re.search(r'<g transform="matrix\(([^)]*)\)"', s)
    gm = [float(v) for v in g.group(1).split(',')]
    out = []
    for pm, bid in re.findall(r'patternTransform="matrix\(([^)]*)\)".*?ffdec:fill-bitmapId="(\d+)"', s, flags=re.S):
        m = [float(v) for v in pm.split(',')]
        # the svg group moves the shape to its bounds: the pattern matrix is already in shape coordinates
        out.append([int(bid)] + m)
    return out


def decor_frame(sid, frame):
    """bitmaps drawn by a frame of a decor sprite: [(bitmap id, matrix in sprite coordinates)]"""
    Gd = DECOR
    inst = R.Instance(Gd, sid, ctrl={sid: frame, '__noactions__': True})
    out = []
    for d in sorted(inst.display):
        e = inst.display[d]
        assert e['inst'] is None and e['cx'] == R.NOCX, (sid, d)
        M = e['matrix']
        for bid, a_, b_, c_, d_, tx, ty in svg_fills(e['char']):
            mm = R.mat_mul(M, dict(a=a_, b=b_, c=c_, d=d_, tx=tx, ty=ty))
            out.append([bid] + [round(mm[k], 4) for k in ('a', 'b', 'c', 'd', 'tx', 'ty')])
    return out


DECOR = R.SWF(W + 'decor.swf', W + 'shp1_decor', Z=1)
meta['decor'] = {
    'bg': [decor_frame(19, 1), decor_frame(19, 2)],
    'bgFront': [decor_frame(14, f) for f in (1, 2, 3)],
    'bgBack': [decor_frame(3, 1)],
}
used = sorted({b[0] for v in meta['decor'].values() for fr in v for b in fr})
for bid in used:
    im = Image.open(W + DECOR_BITMAPS[bid]).convert('RGBA')
    name = 'decor%d' % bid
    os.makedirs(os.path.join(SRC, name), exist_ok=True)
    im.save(os.path.join(SRC, name, '1.png'), optimize=True)
    pivots[name] = [0, 0]
    area[name] = im.width * im.height


# _width of the decor frames (Game.new: c = (_width - 300) / 300)
def clip_width(G, sid, frame):
    inst = R.Instance(G, sid, ctrl={sid: frame, '__noactions__': True})
    cmds = []
    rd = R.Renderer(G, 1)
    rd.collect(inst, R.IDENT, R.NOCX, set(), cmds)
    b = rd.bounds(cmds)
    return round(b[2] - b[0], 3) if b else 0


meta['frontWidth'] = [clip_width(DECOR, 14, f) for f in (1, 2, 3)]
meta['backWidth'] = [clip_width(DECOR, 3, 1)]

# ---------------------------------------------------------------- platform layout (mcPlat)
plat = R.Instance(Gg, 402, ctrl={'__noactions__': True})
for d, e in sorted(plat.display.items()):
    if e['inst'] is not None:
        m = e['matrix']
        meta.setdefault('plat', []).append(dict(d=d, name=e['name'], sid=e['inst'].sid, x=m['tx'], y=m['ty'], sx=m['a']))
meta['platTextBounds'] = Gg.shapes[389]
meta['platMaskBounds'] = Gg.shapes[386]

# ---------------------------------------------------------------- digits of the text fields
# The fields of the original show their digits with the outlines embedded in the SWF (DefineFont2 Arial Black and
# Impact): drawn here as images (exported by FFDec as .ttf); their layout is the Flash one (2 px gutter, baseline at
# the font ascent, advances of the font).
TG = swftext.all_edittexts(W + 'gfx.swf')


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


FONTS = font_layouts(W + 'gfx.swf')
K = C.K


def digit_anims(name, ttf, fid, size, color):
    SS = 4
    lay = FONTS[fid]
    pxs = size * K * SS
    font = ImageFont.truetype(ttf, int(round(pxs)))
    pad = 3
    w = int(math.ceil(max(lay['adv'][c] for c in '0123456789') * size * K)) + 2 * pad + 4
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * K)) + 2 * pad + 2
    ox, oy = pad + 1, pad + int(math.ceil(lay['ascent'] * size * K))
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    rgb = tuple(int(color[i:i + 2], 16) for i in (1, 3, 5))
    for i, ch in enumerate('0123456789'):
        big = Image.new('L', (w * SS, h * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.LANCZOS)
        g = Image.new('RGBA', (w, h), rgb + (0,))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    area[name] = w * h * 10
    return dict(adv=[round(lay['adv'][c] * size, 4) for c in '0123456789'], ascent=round(lay['ascent'] * size, 4))


def field_rect(G, T, sid, tid):
    inst = R.Instance(G, sid, ctrl={'__noactions__': True})
    for d, e in inst.display.items():
        if e['char'] == tid:
            t = T[tid]
            m = e['matrix']
            return dict(x=m['tx'] + t['bounds'][0], y=m['ty'] + t['bounds'][2], w=t['bounds'][1] - t['bounds'][0],
                        align=t.get('align', 'left'))


for key, sid, tid, fid, ttf in (('digitStar', 294, 293, 292, W + 'fonts_gfx/292_Arial Black.ttf'),
                                ('digitScore', 405, 404, 403, W + 'fonts_gfx/403_Impact.ttf')):
    t = TG[tid]
    info = digit_anims(key, ttf, fid, t['height'], t['color'])
    r = field_rect(Gg, TG, sid, tid)
    info.update(x=round(r['x'] + 2, 3), w=round(r['w'] - 4, 3), base=round(r['y'] + 2 + info['ascent'], 3), center=r['align'] == 'center')
    meta[key] = info
    print('%s %s' % (key, info))

json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d, clips json %d bytes' % (
    len(clips), len(area), tot / 1e6, Eg.warnings + Ep.warnings, len(json.dumps(clips, separators=(',', ':')))))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
