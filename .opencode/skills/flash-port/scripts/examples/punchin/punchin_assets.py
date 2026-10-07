"""Builds the Punch-In graphics for KadoKadeo from the original SWF (gfx.swf: the graphics library the released game.swf
was compiled with, same shapes and timelines, readable instance names).

What the game attaches (Game.hx, Boxer.hx, Afro.hx of the original):
  - mcAfro (the opponent) and mcPlayer (the player, seen from behind): only driven by gotoAndStop (labels, then frame
    numbers), exported as Clips of CUT layers (the parts of the body moved by matrices: few textures). Their nested
    clips stop on their first frame, except sprite 73 in mcPlayer's sprite 76 (frames 1..3 looping): a nested clip.
    The code colours mcPlayer (Col.setPercentColor: the bonus colours): white silhouettes of every layer (`white`);
  - mcBg (decor, ring, ropes: one picture, moved by the code; its _width is measured);
  - mcStamina: its frame, the gauge (sprite 64) under the mask `mask` (sprite 62, a 100 x 12 rectangle whose _xscale
    the code sets: drawn as a piece of the gauge picture, no mask) and the overlay;
  - mcChrono: the bar under its text field `label` and the shine over it; the field (Verdana Bold Italic, a device
    font: glyphs drawn from the system font);
  - mcText: `sub` (its text field `label`, Verdana Bold Italic embedded in the SWF) slides in, turns cream and
    shrinks: the matrix / colour of `sub` on each frame (tables), the glyphs of the field.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: punchin_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/punchin holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math, struct, zlib
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
from fontTools.ttLib import TTFont
import swfrender as R
import clipexport as C
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'punchin', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
K = C.K

# Boxer.ANIM / Afro.ANIM: the frames the code shows (from the label of each animation to its end)
def anim_frames(sid, ends):
    labels = G.sprites[sid].labels
    out = set()
    for lab, end in ends.items():
        out |= set(range(labels[lab], end + 1))
    return sorted(out)


AFRO_ENDS = dict(stand=19, attack=26, attack_missed=37, attack_hit=45, **{'def': 62}, def_anim=67, def_end=71, ouch=85,
                 move2side=95, move2center=105, side_stand=117, side_ouch=123, side_def=141, side_def_anim=146,
                 side_def_end=152)
PLAYER_ENDS = dict(stand=19, attack=24, attack_missed=29, attack_hit=42, hook=51, hook_missed=59, hook_hit=72, ouch=86,
                   move2side=92, move2center=103, side_stand=119)
AFRO_FRAMES = anim_frames(47, AFRO_ENDS)
PLAYER_FRAMES = anim_frames(96, PLAYER_ENDS)

E = C.Exporter(G, SRC, '', {})
# the shines of the gloves: white shapes placed with a GlowFilter (blur 17) in "add" mode (Clip draws them ADD)
E.effect_layers = True
# sprite 73 (in mcPlayer's sprite 76) loops on frames 1..3 (gotoAndPlay(1) on frame 3): frames 4..6 are never shown
E.frames_for[73] = [1, 2, 3]
E.export(47, 'mcAfro', strategy='cut', frames=AFRO_FRAMES)
E.export(96, 'mcPlayer', strategy='cut', frames=PLAYER_FRAMES, white=True)

clips, pivots, area = E.clips, E.pivots, E.area
meta = {'afroFrames': AFRO_FRAMES, 'playerFrames': PLAYER_FRAMES}


def cmds_of(sid, frame=1, M=R.IDENT, cx=R.NOCX, only=None):
    """draw commands of sprite sid on a frame (only: the depths kept)"""
    inst = R.Instance(G, sid, ctrl={'__noactions__': True, sid: frame})
    if only is not None:
        inst.display = {d: e for d, e in inst.display.items() if d in only}
    out = []
    R.Renderer(G, K).collect(inst, M, cx, set(), out)
    return out


def picture(name, cmds, margin=0.5):
    imgs, reg = E.render([cmds], K, margin=margin)
    E.write_anim(name, imgs, reg)
    return dict(x=round(-reg[0] / K, 4), y=round(-reg[1] / K, 4), w=imgs[0].size[0] / K, h=imgs[0].size[1] / K)


# ---------------------------------------------------------------- mcBg: one picture (moved by the code)
E.export(105, 'mcBg', strategy='flat')


def shape_bounds(sid):
    """ShapeBounds of DefineShape `sid` (Flash's _width / _height use them)"""
    raw = open(W + 'gfx.swf', 'rb').read()
    data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
    bb = SD.Bits(data, 8); bb.rect(); bb.u16(); bb.u16()
    for code, body in SD.read_tags(data, bb.pos, len(data)):
        if code in (2, 22, 32, 83) and struct.unpack_from('<H', body, 0)[0] == sid:
            b = SD.Bits(body, 2)
            return b.rect()
    raise KeyError(sid)


def flash_bounds(sid):
    """bounds of a sprite as Flash measures them (_width): each shape's bounds through its matrix"""
    inst = R.Instance(G, sid, ctrl={'__noactions__': True})
    xs, ys = [], []

    def walk(inst, M):
        for d, e in inst.display.items():
            m = R.mat_mul(M, e['matrix'])
            if e['inst'] is not None:
                walk(e['inst'], m)
            elif e['char'] in G.shapes:
                x0, x1, y0, y1 = shape_bounds(e['char'])
                for px, py in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
                    xs.append(m['a'] * px + m['c'] * py + m['tx'])
                    ys.append(m['b'] * px + m['d'] * py + m['ty'])
    walk(inst, R.IDENT)
    return min(xs), max(xs), min(ys), max(ys)


b = flash_bounds(105)
# Flash keeps the bounds in twips
meta['bgWidth'] = round(round((b[1] - b[0]) * 20) / 20, 4)
print('mcBg bounds', b, 'width', meta['bgWidth'])

# ---------------------------------------------------------------- mcStamina
# depth 4 the frame, 5 the mask (sprite 62: shape 61, x 0..100), 7 the gauge (sprite 64), 12 the overlay
st = {d: e for d, e in R.Instance(G, 66, ctrl={'__noactions__': True}).display.items()}
assert st[5]['name'] == 'mask' and st[5]['clip'] == 9 and st[7]['char'] == 64, st
meta['stFrame'] = picture('stFrame', cmds_of(66, only={4}))
meta['stGauge'] = picture('stGauge', cmds_of(66, only={7}), margin=0)
meta['stOver'] = picture('stOver', cmds_of(66, only={12}))
mb = shape_bounds(61)
mm = st[5]['matrix']
assert mm['a'] == 1 and mm['d'] == 1 and mm['b'] == 0 and mm['c'] == 0, mm
meta['stMask'] = dict(x=round(mm['tx'] + mb[0], 4), w=round(mb[1] - mb[0], 4), y0=round(mm['ty'] + mb[2], 4),
                      y1=round(mm['ty'] + mb[3], 4))
print('stamina', meta['stGauge'], meta['stMask'])

# ---------------------------------------------------------------- mcChrono: under / over its field
meta['chUnder'] = picture('chUnder', cmds_of(56, only={2}))
meta['chOver'] = picture('chOver', cmds_of(56, only={4}))


# ---------------------------------------------------------------- text fields
def font_layouts(path):
    """DefineFont2 / 3 layouts: font id -> ascent, descent, advances (em fractions)"""
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
            continue
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


def glyph_anims(name, ttf, lay, chars, size):
    """one white image per character, its pivot on the pen position at the baseline (tinted at run time)"""
    SS = 4
    font = ImageFont.truetype(ttf, int(round(size * K * SS)))
    pad = 4
    w = int(math.ceil(max(lay['adv'][c] for c in chars) * size * K)) + 2 * pad + 8
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * K)) + 2 * pad + 2
    ox, oy = pad + 3, pad + int(math.ceil(lay['ascent'] * size * K))
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    for i, ch in enumerate(chars):
        big = Image.new('L', (w * SS, h * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.LANCZOS)
        g = Image.new('RGBA', (w, h), (255, 255, 255, 0))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    area[name] = w * h * len(chars)
    return dict(anim=name, chars=chars, adv=[round(lay['adv'][c] * size, 4) for c in chars])


TX = swftext.all_edittexts(W + 'gfx.swf')
FONTS = font_layouts(W + 'gfx.swf')


def field_info(sid, tid, glyphs, lay):
    """Flash text field layout (2 px gutter, first baseline = top + 2 + ascent) in the coordinates of sprite sid"""
    inst = R.Instance(G, sid, ctrl={'__noactions__': True})
    e = [e for e in inst.display.values() if e['char'] == tid][0]
    m, t = e['matrix'], TX[tid]
    x0, x1, y0 = t['bounds'][0], t['bounds'][1], t['bounds'][2]
    assert abs(m['a'] - 1) < 1e-6 and abs(m['d'] - 1) < 1e-6 and m['b'] == 0 and m['c'] == 0, m
    assert t['align'] == 'center' and not t['html'], t
    info = dict(glyphs)
    info.update(x=round(m['tx'] + x0 + 2, 3), w=round(x1 - x0 - 4, 3),
                base=round(m['ty'] + y0 + 2 + lay['ascent'] * t['height'], 3), center=True,
                color=int(t['color'][1:], 16))
    return info


# mcChrono.label: Verdana Bold Italic as a device font (not embedded): "mm:ss"
tc = TX[54]
assert not tc['useOutlines'] and tc['fontInfo']['name'] == 'Verdana' and tc['fontInfo']['bold'] and tc['fontInfo']['italic']
VERDANA = '/System/Library/Fonts/Supplemental/Verdana Bold Italic.ttf'
CH = '0123456789:'
lay = ttf_layout(VERDANA, CH)
meta['chronoField'] = field_info(56, 54, glyph_anims('glyphChrono', VERDANA, lay, CH, tc['height']), lay)

# mcText.sub.label: Verdana Bold Italic embedded (font 53): the messages of the game
tm = TX[57]
assert tm['useOutlines'] and tm['font'] in FONTS
MSG = ' !0123456789ACEMOBQaeinoprtqsu'
lay = FONTS[tm['font']]
assert set(MSG) <= set(lay['adv']), MSG
meta['msgField'] = field_info(58, 57, glyph_anims('glyphMsg', W + 'fonts_gfx/53_Verdana.ttf', lay, MSG, tm['height']), lay)
print('chrono field', {k: v for k, v in meta['chronoField'].items() if k != 'adv'})
print('msg field', {k: v for k, v in meta['msgField'].items() if k != 'adv'})

# mcText: the placement of `sub` (depth 1) on each frame: [x, y, scale, multiplied colour (0..1), added colour]
sd = G.sprites[59]
rows, glows = [], []
for f in range(1, sd.nframes + 1):
    inst = R.Instance(G, 59, ctrl={'__noactions__': True, 59: f})
    e = inst.display.get(1)
    if e is None:
        rows.append(None)
        glows.append(None)
        continue
    m, cx = e['matrix'], e['cx']
    assert m['b'] == 0 and m['c'] == 0 and abs(m['a'] - m['d']) < 1e-6, m
    assert cx['mult'][0] == cx['mult'][1] == cx['mult'][2] and cx['mult'][3] == 1 and cx['add'][3] == 0, cx
    rows.append([round(m['tx'], 4), round(m['ty'], 4), round(m['a'], 5), round(cx['mult'][0], 5), list(cx['add'][:3])])
    # its glow (red to white while it slides in; strength 0 = none): [blurX, blurY, strength, colour]
    fl = [x for x in e.get('filters') or [] if not (x['type'] == 'glow' and (x['strength'] <= 0 or x['blurX'] < 1))]
    assert all(x['type'] == 'glow' and not x['inner'] and not x['knockout'] and x['passes'] == 1 and x['color'][3] == 255
               for x in fl), fl
    glows.append([round(fl[0]['blurX'], 4), round(fl[0]['blurY'], 4), round(fl[0]['strength'], 6),
                  (fl[0]['color'][0] << 16) | (fl[0]['color'][1] << 8) | fl[0]['color'][2]] if fl else None)
meta['textFrames'] = rows
meta['textGlows'] = glows
meta['textLabels'] = dict(sd.labels)
print('mcText', sd.actions, rows)

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
