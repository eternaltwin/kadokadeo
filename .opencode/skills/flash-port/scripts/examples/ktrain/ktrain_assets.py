"""Builds the K-Train graphics for KadoKadeo from the original SWF (gfx.swf: the graphics of the released game.swf, same
shapes and timelines, readable instance names: game.swf obfuscates hit1 / hit2 / m / c / p / f).

K-Train is drawn with bitmaps (the artists' PNG) in shapes filled without smoothing: they are taken from the FFDec
export at zoom 2 composed with nearest sampling, so every texture is the bitmap doubled (2 px per Flash pixel, Flash
zoomed x2); the few vector shapes (smoke, sparks, footprints, the station line) are anti-aliased at that resolution.

Every symbol the game attaches is exported as a Clip (timeline tables played by ktrain.Clip, clipexport.py):
  - the hit zones (hit1 / hit2 of the obstacles, tunnels and station, smc of the driver) are black shapes placed with
    the blend mode "alpha": without a parent in "layer" mode Flash draws nothing, they only count in getBounds. They
    are taken out of the pictures (bounds below);
  - the shadows of the obstacles (mcObjets*_ombre: their sprite is placed in "multiply") are exported plain and
    multiplied by the game (the whole clip); the shadows inside mcTunnels / mcStation stay nested clips with their
    blend mode;
  - the 6 ground bitmaps (mcBg_*, the frames of mcBg are one of them, flipped or not) at their native resolution: they
    are only drawn into the bitmaps of the scenes (SceneManager);
  - the smoke (mcSmoke: its smc grows and blurs over 16 frames, smc.smc is one of 6 puffs chosen by the code): one clip
    per puff, its frames composed here with the blur of the timeline, at 0.5 px per Flash pixel (blurred pictures);
  - the bonus text (mcBonus: a text field in the embedded font Edmunds with two drop shadows; the code writes the
    price, 4 possible values): one picture per price;
  - the lever panel (mcLevier: m, c, p, f driven by the code), the station (2 frames), tunnels and gate (5 frames),
    the obstacles, gems, rails, signs, sparks, feathers, debris, the driver and the locomotive.
What the code measures on the display (getBounds, _width, _height of the clips and of their hit zones) is measured on
the SWF like Flash does (rectangles of the shapes through the matrices, in twips) and written in meta.json.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: ktrain_assets.py <out dir>   (after prepare_game.sh + the zoom 2 export, see rebuild_assets.sh)
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

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'ktrain', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp2_gfx', Z=2)       # 2 px per Flash pixel
Gb = R.SWF(W + 'gfx.swf', W + 'shp2_gfx', Z=2)      # untouched timelines, for the measures
for X in (G, Gb):
    X.flash_replace = True
    X.nearest = True
K = C.K


def rng(*spans):
    out = []
    for a, b in spans:
        out += list(range(a, b + 1))
    return out


# ---------------------------------------------------------------- what Flash does not draw
# the hit zones: placed with the blend mode "alpha" (nothing drawn without a "layer" parent): out of the pictures
hidden = 0
for sid, sd in G.sprites.items():
    for fi, ops in enumerate(sd.frames):
        keep = []
        for k, v in ops:
            if k == 'place' and v.get('blend') == 'alpha':
                assert not v.get('move'), (sid, fi)
                hidden += 1
                continue
            keep.append((k, v))
        sd.frames[fi] = keep
print('hit zones taken out of the pictures:', hidden)
# the shadows of the obstacles: their only sprite is placed in "multiply"; the game multiplies the whole clip
SHADOWS = {107: 'mcObjets_neige_ombre', 159: 'mcObjets_ombre', 169: 'mcObjets_terre_ombre'}
for sid in SHADOWS:
    for ops in G.sprites[sid].frames:
        for k, v in ops:
            if k == 'place' and v.get('blend') == 'multiply':
                v['blend'] = None
# shadows inside mcTunnels (mcOmbre_tunnels 263, mcOmbre_portique 247) and mcStation (mcOmbre_station 331): nested clips
# with their blend mode (Clip applies it to their picture)
INNER_SHADOWS = (263, 247, 331)


class Exporter(C.Exporter):
    def alive(self, sid, ctrl):
        return sid in INNER_SHADOWS or super().alive(sid, ctrl)


E = Exporter(G, SRC, '', {})
E.clip_res = [1.0]
E.effects = True

E.export(16, 'mcLoco', strategy='flat')
E.export(55, 'mc_ombre_train', strategy='flat')
E.export(237, 'mcPilote', strategy='flat')
E.export(73, 'ombre_pilote', strategy='flat')
E.export(8, 'mcFoot', strategy='flat')
E.export(345, 'mcRail', strategy='flat', frames=[1])          # RailManager: gotoAndStop(1)
E.export(208, 'mcObjets_terre', strategy='flat')
E.export(169, 'mcObjets_terre_ombre', strategy='flat')
E.export(134, 'mcObjets_neige', strategy='flat')
E.export(107, 'mcObjets_neige_ombre', strategy='flat')
E.export(94, 'mcObjets_herbe', strategy='flat')
E.export(313, 'mcObjets', strategy='flat')
E.export(159, 'mcObjets_ombre', strategy='flat')
E.export(272, 'mcTunnels', strategy='flat')
E.export(334, 'mcStation', strategy='flat')
E.export(210, 'mcLimite_station', strategy='flat')
E.export(244, 'mcPaneaux', strategy='flat')
E.export(281, 'mcTresors', strategy='flat')
E.export(85, 'mcPlume', strategy='flat')                     # plays its 4 frames in a loop
E.export(70, 'mcDebris', strategy='flat')
E.export(76, 'fxSpark')                                      # a white pixel coloured by its timeline, then stop
E.export(49, 'mcLevier', code=('m', 'c', 'p', 'f'))

# the ground bitmaps (mcBg_*: 300 x 300), native resolution; the frames of mcBg: [bitmap, flipped vertically]
BG = {348: 'mcBg_terre', 350: 'mcBg_neige', 352: 'mcBg_herbe', 354: 'mcBg_terre_neige', 356: 'mcBg_neige_herbe',
      358: 'mcBg_herbe_terre'}
for sid, nm in BG.items():
    E.export(sid, nm, strategy='flat', res=0.5)
bg_frames = []
inst = R.Instance(Gb, 359, ctrl={'__noactions__': True})
for f in range(1, 13):
    inst = R.Instance(Gb, 359, ctrl={'__noactions__': True, 359: f})
    es = list(inst.display.values())
    assert len(es) == 1 and es[0]['char'] in BG, f
    m = es[0]['matrix']
    assert m['a'] == 1 and m['b'] == 0 and m['c'] == 0 and abs(abs(m['d']) - 1) < 1e-9 and m['tx'] == 150 and m['ty'] == 150, (f, m)
    bg_frames.append([BG[es[0]['char']], m['d'] < 0])
print('mcBg frames', bg_frames)
# mcBg itself: attached for a moment by SceneManager.getScene (its frame is read, it is drawn into the bitmap by Bmp)
E.clips['mcBg'] = dict(n=12, r=1.0, layers=[], acts={})

# ---------------------------------------------------------------- smoke
# mcSmoke: smc (sprite 321) scaled and blurred by the timeline (blurX = blurY, quality 1) over 16 frames, stop on 16;
# smc.smc (sprite 320) shows the puff chosen by the code (gotoAndStop(random(6) + 1))
SMOKE_RES = 0.25
sm_rows = []
for f in range(1, 17):
    inst = R.Instance(Gb, 322, ctrl={'__noactions__': True, 322: f})
    es = list(inst.display.values())
    assert len(es) == 1 and es[0]['char'] == 321 and es[0]['name'] == 'smc', f
    fl = es[0]['filters']
    assert len(fl) == 1 and fl[0]['type'] == 'blur' and fl[0]['blurX'] == fl[0]['blurY'] and fl[0]['passes'] == 1, fl
    sm_rows.append((es[0]['matrix'], fl[0]['blurX']))
inner = R.Instance(Gb, 321, ctrl={'__noactions__': True})
assert [e['char'] for e in inner.display.values()] == [320]
assert list(inner.display.values())[0]['matrix'] == R.IDENT
rd = R.Renderer(Gb, Gb.Z)
for v in range(1, 7):
    cmd_lists = []
    for m, b in sm_rows:
        puff = R.Instance(Gb, 320, ctrl={'__noactions__': True, 320: v})
        cmds = []
        rd.collect(puff, m, R.NOCX, set(), cmds)
        cmd_lists.append((cmds, b))
    # common canvas: the largest frame + its blur
    bb = None
    for cmds, b in cmd_lists:
        x0, y0, x1, y1 = rd.bounds(cmds)
        x0, y0, x1, y1 = x0 - b, y0 - b, x1 + b, y1 + b
        bb = (x0, y0, x1, y1) if bb is None else (min(bb[0], x0), min(bb[1], y0), max(bb[2], x1), max(bb[3], y1))
    step = 1.0 / (K * SMOKE_RES)
    ox, oy = math.floor(bb[0] / step) * step, math.floor(bb[1] / step) * step
    ex, ey = math.ceil(bb[2] / step) * step, math.ceil(bb[3] / step) * step
    Z = Gb.Z
    Wz, Hz = int(round((ex - ox) * Z)), int(round((ey - oy) * Z))
    imgs = []
    for cmds, b in cmd_lists:
        canvas = np.zeros((Hz, Wz, 4), dtype=np.float32)
        rd.draw(cmds, canvas, (ox, oy))
        chans = [R.box_blur(canvas[..., c], b * Z, b * Z, 1) for c in range(4)]
        canvas = np.stack(chans, axis=-1)
        im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
        im = im.resize((int(round(Wz * K * SMOKE_RES / Z)), int(round(Hz * K * SMOKE_RES / Z))), Image.BOX)
        imgs.append(im.convert('RGBA'))
    E.write_anim('smoke%d' % v, imgs, (-ox * K * SMOKE_RES, -oy * K * SMOKE_RES))
    E.clips['mcSmoke%d' % v] = dict(n=16, r=SMOKE_RES, layers=[dict(k=0, a='smoke%d' % v, t=list(range(1, 17)))],
                                    acts={'16': [['s']]})


# ---------------------------------------------------------------- mcBonus: the price
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


TX = swftext.all_edittexts(W + 'gfx.swf')
FONTS = font_layouts(W + 'gfx.swf')
t = TX[51]
assert t['font'] == 50 and t['align'] == 'center' and not t['html'] and t['color'] == '#ffcc00', t
lay = FONTS[50]
binst = R.Instance(Gb, 52, ctrl={'__noactions__': True})
be = list(binst.display.values())
assert len(be) == 1 and be[0]['char'] == 51 and be[0]['name'] == 'smc', be
bm = be[0]['matrix']
assert bm['b'] == 0 and bm['c'] == 0 and bm['a'] == 1, bm
shadows = be[0]['filters']
assert [f['type'] for f in shadows] == ['dropshadow', 'dropshadow'], shadows
TTF = W + 'fonts_gfx/50_Edmunds.ttf'
SS = 4
size = t['height']
fx0, fx1, fy0, fy1 = t['bounds']
for price in (5000, 8000, 12000, 24000):
    text = str(price)
    # the field (2 px gutter, centred, first baseline at top + 2 + ascent), at Z = K px per Flash pixel, supersampled
    lw = sum(lay['adv'][ch] for ch in text) * size
    pen0 = fx0 + 2 + ((fx1 - fx0 - 4) - lw) / 2
    base = fy0 + 2 + lay['ascent'] * size
    # canvas in mcBonus coordinates around the text
    cx0, cy0 = math.floor(bm['tx'] + pen0 - 6), math.floor(bm['ty'] + (fy0 - 2) * bm['d'])
    cx1, cy1 = math.ceil(bm['tx'] + pen0 + lw + 6), math.ceil(bm['ty'] + (fy1 + 2) * bm['d'])
    cw, ch = (cx1 - cx0) * K, (cy1 - cy0) * K
    font = ImageFont.truetype(TTF, int(round(size * K * SS)))
    big = Image.new('L', (cw * SS, int(math.ceil(ch * SS / bm['d']))), 0)
    dr = ImageDraw.Draw(big)
    pen = pen0
    for chh in text:
        x = (bm['tx'] + pen - cx0) * K * SS
        y = (base - (cy0 - bm['ty']) / bm['d']) * K * SS
        dr.text((x, y), chh, font=font, fill=255, anchor='ls')
        pen += lay['adv'][chh] * size
    al = big.resize((cw, ch), Image.LANCZOS)          # (the field is scaled by sy = bm['d'])
    a = np.asarray(al, dtype=np.float32) / 255.0
    rgb = [int(t['color'][i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    layer = np.stack([a * rgb[0], a * rgb[1], a * rgb[2], a], axis=-1).astype(np.float32)
    for f in shadows:
        layer = R.apply_filter(layer, f, K)
    im = Image.fromarray(np.clip(layer * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
    nm = 'bonus%d' % price
    E.write_anim(nm, [im], (-cx0 * K, -cy0 * K))
    E.clips['mcBonus%d' % price] = dict(n=1, r=1.0, layers=[dict(k=0, a=nm, t=[1])])

clips, pivots, area = dict(E.clips), dict(E.pivots), dict(E.area)


# ---------------------------------------------------------------- values the code reads on the display
def tw(v):
    return round(v * 20) / 20.0


def trect(r, m):
    """rectangle (xmin, ymin, xmax, ymax) through a matrix: Flash transforms the corners (twips)"""
    xs, ys = [], []
    for x in (r[0], r[2]):
        for y in (r[1], r[3]):
            xs.append(m['a'] * x + m['c'] * y + m['tx'])
            ys.append(m['b'] * x + m['d'] * y + m['ty'])
    return (tw(min(xs)), tw(min(ys)), tw(max(xs)), tw(max(ys)))


def union(a, b):
    if a is None:
        return b
    if b is None:
        return a
    return (min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3]))


def inst_bounds(inst):
    """getBounds of an instance in its own coordinates (every child, visible or not, its blend mode whatever)"""
    out = None
    for d, e in sorted(inst.display.items()):
        if e['inst'] is not None:
            r = inst_bounds(e['inst'])
        elif e['char'] in Gb.shapes:
            s = Gb.shapes[e['char']]
            r = (s[0], s[2], s[1], s[3])
        elif e['char'] in Gb.texts:
            s = Gb.texts[e['char']]
            r = (s[0], s[2], s[1], s[3])
        else:
            r = None
        if r is not None:
            out = union(out, trect(r, e['matrix']))
    return out


def clip_bounds(sid, f):
    return inst_bounds(R.Instance(Gb, sid, ctrl={'__noactions__': True, sid: f}))


def sub_bounds(sid, f, name):
    """bounds of the named child in the clip's coordinates (Flash finds the child of lowest depth with that name)"""
    inst = R.Instance(Gb, sid, ctrl={'__noactions__': True, sid: f})
    for d, e in sorted(inst.display.items()):
        if e['name'] == name:
            if e['inst'] is None:
                return None     # (a shape is not a MovieClip: mc.name is undefined)
            r = inst_bounds(e['inst'])
            return None if r is None else list(trect(r, e['matrix']))
    return None


MEASURED = {
    'mcObjets_terre': 208, 'mcObjets_terre_ombre': 169, 'mcObjets_neige': 134, 'mcObjets_neige_ombre': 107,
    'mcObjets_herbe': 94, 'mcObjets': 313, 'mcObjets_ombre': 159, 'mcTunnels': 272, 'mcStation': 334,
    'mcPaneaux': 244, 'mcTresors': 281, 'mcPilote': 237, 'ombre_pilote': 73, 'mcLoco': 16, 'mcDebris': 70,
    'mcFoot': 8,
}
HITS = {'mcObjets_terre': ('hit1', 'hit2'), 'mcObjets_neige': ('hit1', 'hit2'), 'mcObjets_herbe': ('hit1', 'hit2'),
        'mcObjets': ('hit1', 'hit2'), 'mcObjets_terre_ombre': ('hit1', 'hit2'), 'mcObjets_neige_ombre': ('hit1', 'hit2'),
        'mcObjets_ombre': ('hit1', 'hit2'), 'mcTunnels': ('hit1', 'hit2'), 'mcStation': ('hit1',), 'mcPilote': ('smc',)}
meta = {'bgFrames': bg_frames, 'bounds': {}, 'sub': {}}
for nm, sid in MEASURED.items():
    n = Gb.sprites[sid].nframes
    meta['bounds'][nm] = [None if b is None else list(b) for b in (clip_bounds(sid, f) for f in range(1, n + 1))]
    for h in HITS.get(nm, ()):
        rows = [sub_bounds(sid, f, h) for f in range(1, n + 1)]
        if any(r is not None for r in rows):
            meta['sub'].setdefault(nm, {})[h] = rows
# mcLevier: positions of its children the code reads (p._y, c._x, c._y)
lev = R.Instance(Gb, 49, ctrl={'__noactions__': True})
for e in lev.display.values():
    if e['name'] in ('p', 'c', 'f'):
        meta['lev_' + e['name']] = [e['matrix']['tx'], e['matrix']['ty']]
print('levier', {k: v for k, v in meta.items() if k.startswith('lev_')})
print('bounds mcLoco', meta['bounds']['mcLoco'], 'mcPilote', meta['bounds']['mcPilote'][:2], 'smc', meta['sub']['mcPilote']['smc'][:1])
print('station hit1', meta['sub']['mcStation']['hit1'], 'tunnels', meta['sub']['mcTunnels'])

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
