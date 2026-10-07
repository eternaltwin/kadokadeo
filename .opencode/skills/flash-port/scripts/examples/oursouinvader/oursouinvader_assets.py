"""Builds the Oursouinvader graphics for KadoKadeo from the original SWF (gfx.swf: the graphics of the released
temple.swf, same shapes and timelines, readable instance names; decor.swf is a leftover space theme whose mcBg the
released game does not show: the thumbnails of the game show gfx.swf's sea bottom).

Every symbol the game attaches is exported as a Clip (timeline tables played by oursouinvader.Clip, see clipexport.py):
  - the hero (mcHero: stand / shoot / die, its eyes blinking at random: sprite 213, a frame script);
  - the monsters (mcBadBoy, mcOcto, mcBomber, mcOyster, mcBoss): their pincers / tentacles / shells start at a random
    frame (first frame scripts), the eye the code turns towards the hero stays a nested clip (cEyeI.mcEyeAnim,
    mcOctoEye.mcOctoEyeAnim); the boss is shown at 200 % (textures at res 2);
  - the shots (mcSpike: its frame 20 calls obj.kill(), mcShootOcto, mcShootBomber, mcShootPearl: res 2, the boss
    stretches it to 200 % in x), the bonuses (mcBonus, 7 frames; frame 6 through a ColorMatrixFilter), the shield
    (mcBubble), the limit line (mcLimit), the small bubble (mcSmallBubble: the particles; mcSmallBubble1 at 1 pixel
    per Flash pixel: the bubbles drawn into the bitmaps of Game.updateBurbulisseur);
  - the background mcBg: the bitmap 246 at its native resolution;
  - the texts (font "Sweet as candy" of the SWF): the scores that rise (mcScore: only 8 values, their white
    GlowFilter(2, 2, 5) baked), the glyphs of "VAGUE n" (mcLevelDisplay: glow and blur at run time) with their layout.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: oursouinvader_assets.py <out dir>   (after prepare_game.sh: $KKP_WORK/oursouinvader holds gfx.swf and its exports)
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

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'oursouinvader', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
K = C.K

RM = [['x', 'rmSelf']]
# frame scripts that are not plain playhead moves (decompiled in as_gfx/, the same in the released temple.swf)
CUSTOM = {
    (13, 39): RM,                                   # mcBubble (burst): removeMovieClip("")
    # startBAnim = random(lPince._totalframes); lPince.gotoAndPlay(startBAnim + 1); rPince.gotoAndPlay(startBAnim + 20)
    (142, 1): [['x', 'pinceB']],
    (142, 50): [['g', 2, 1], ['x', 'xs100']],       # gotoAndPlay(2); _xscale = 100 (end of "ouch")
    (142, 80): RM,
    # startTAnim = random(lTente._totalframes); lTente.gotoAndPlay(startTAnim); rTente.gotoAndPlay(startTAnim)
    (143, 1): [['x', 'tente']],
    (143, 40): [['g', 2, 1], ['x', 'xs100']],
    (143, 73): RM,
    (65, 1): [['x', 'tente']],                      # mcBoss: the same as mcOcto
    (65, 40): [['g', 2, 1], ['x', 'xs200']],
    (65, 73): RM,
    # startAnim = random(lpince._totalframes); lpince.gotoAndPlay(startAnim); rpince.gotoAndPlay(startAnim)
    (183, 1): [['x', 'pinceA']],
    (183, 76): RM,
    # the hero's eyes: compt = random(12) + 60; if (compt == 61) eyeClose.play() (frame 3 goes back to 2)
    (213, 1): [],
    (213, 2): [['x', 'blink']],
    (235, 73): RM,                                  # mcHero (die)
    (238, 20): [['x', 'objKill']],                  # mcSpike (dead): obj.kill()
    # startBAnim = random(mcCokTop._totalframes); mcCokTop.gotoAndPlay(startBAnim + 1); mcCokBottom.gotoAndPlay(startBAnim + 20)
    (122, 1): [['x', 'cok']],
    (122, 57): [['g', 2, 1], ['x', 'xs100']],       # gotoAndStop("stand"); play(); _xscale = 100
    (122, 130): RM,
}

E = C.Exporter(G, SRC, '', CUSTOM)
# the glow / blend mode of nested clips applied at run time (mcHero's death: the white glow of the burst partExplosion,
# the rays drawn "add")
E.effects = True
E.code_for = {
    153: ('mcEyeAnim',),        # mcBadBoy.cEyeI.mcEyeAnim._rotation (Monster.move)
    52: ('mcOctoEyeAnim',),     # mcOcto / mcBoss .mcOctoEye.mcOctoEyeAnim._rotation
    213: ('eyeClose',),         # the hero's blink
}
# the burst of the hero's death (frame by frame shapes 184..202): drawn by partExplosion (cyan) and by depth 5 of mcHero
# (dark blue), both solid colours: one white sequence tinted at run time (shown at ~0.8 / 0.6)
E.families = [list(range(184, 203))]
E.family_res = 0.75
E.strategy_for = {203: 'cut'}

E.export(235, 'mcHero', strategy='flat', cut_depths=(5,))
E.export(183, 'mcBadBoy', code=('cEyeI', 'lpince', 'rpince'))
E.export(143, 'mcOcto', code=('mcOctoEye', 'lTente', 'rTente'))
E.export(142, 'mcBomber', code=('lPince', 'rPince'))
E.export(122, 'mcOyster', code=('mcCokTop', 'mcCokBottom'))
# shown at 200 % (Monster.initState)
E.export(65, 'mcBoss', code=('mcOctoEye', 'lTente', 'rTente'), res=2.0)
E.export(238, 'mcSpike')
E.export(245, 'mcShootOcto')
E.export(74, 'mcShootBomber')
# the boss's shot: _xscale = 200
E.export(77, 'mcShootPearl', res=2.0)
E.export(39, 'mcBonus')
# mcBonus frame 6 (fire rate) shows the clip of frame 5 (triple shot) through a ColorMatrixFilter (a hue shift), which
# the exporter does not keep on a nested clip: its own layer on frame 6, the matrix applied at run time ('cm': Flash's
# 4 x 5 matrix, offsets in 0..255)
_cm = [f for k, v in G.sprites[39].frames[5] if k == 'place' for f in (v.get('filters') or [])]
assert len(_cm) == 1 and _cm[0]['type'] == 'colormatrix', _cm
_L = [Ly for Ly in E.clips['mcBonus']['layers'] if Ly['k'] == 2 and Ly['p'][4] and Ly['p'][5]]
assert len(_L) == 1 and _L[0]['p'][4] == _L[0]['p'][5], E.clips['mcBonus']
_L6 = dict(_L[0], p=[0] * 7, cm=[round(v, 6) for v in _cm[0]['matrix']])
_L6['p'][5] = max(Ly['p'][f] for Ly in E.clips['mcBonus']['layers'] if Ly['k'] == 2 for f in range(7)) + 1
_L[0]['p'][5] = 0
_L6.pop('fl', None)
E.clips['mcBonus']['layers'].insert(E.clips['mcBonus']['layers'].index(_L[0]) + 1, _L6)
E.export(13, 'mcBubble')
E.export(18, 'mcLimit')
# particles at 50 - 100 %
E.export(5, 'mcSmallBubble', res=1.5)
# the bubbles drawn into the bitmaps of Game.updateBurbulisseur (300 x h BitmapData: 1 pixel per Flash pixel, shown x2)
E.export(5, 'mcSmallBubble1', res=0.5)

ROOTS = ['mcHero', 'mcBadBoy', 'mcOcto', 'mcBomber', 'mcOyster', 'mcBoss', 'mcSpike', 'mcShootOcto', 'mcShootBomber',
         'mcShootPearl', 'mcBonus', 'mcBubble', 'mcLimit', 'mcSmallBubble', 'mcSmallBubble1']
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

# ---------------------------------------------------------------- the background: bitmap 246 (shape 247 of mcBg)
assert [v['char'] for k, v in G.sprites[248].frames[0] if k == 'place'] == [247]
svg = open(W + 'svg_gfx/247.svg').read()
assert 'patternTransform="matrix(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)"' in svg and 'width="300"' in svg, 'bg fill matrix'
bg = Image.open(W + 'img_gfx/246.jpg').convert('RGBA')
assert bg.size == (300, 300)
E.write_anim('bg', [bg], (0, 0))
# one picture at native resolution: 1 texture pixel per Flash pixel (r = 0.5)
E.clips['mcBg'] = dict(n=1, r=0.5, layers=[dict(k=0, a='bg', t=[1])])

clips, pivots, area = dict(E.clips), dict(E.pivots), dict(E.area)
meta = {}


# ---------------------------------------------------------------- texts: font "Sweet as candy" (DefineFont3 1)
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
TTF = W + 'fonts_gfx/1_Sweet as candy.ttf'
LAY = FONTS[1]
print('font glyphs', ''.join(chr(c) for c in LAY['codes']))


def field_layout(sid, tid):
    """layout of text field tid placed in sprite sid: text area (inside the 2 px gutter) and first baseline"""
    t = TX[tid]
    assert t['font'] == 1 and t['align'] == 'center' and not t['html'], t
    inst = R.Instance(G, sid, ctrl={'__noactions__': True})
    m = [e for e in inst.display.values() if e['char'] == tid][0]['matrix']
    assert abs(m['a'] - 1) < 0.002 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0, m
    size = t['height']
    return dict(x=m['tx'] + t['bounds'][0] + 2, w=t['bounds'][1] - t['bounds'][0] - 4,
                base=m['ty'] + t['bounds'][2] + 2 + LAY['ascent'] * size, size=size, color=t['color'])


def text_alpha(s, lay, res, SS=4):
    """alpha of a one-line centred text field (Flash pixels * K * res), and its origin (the clip's) in the image"""
    sc = K * res
    size = lay['size']
    font = ImageFont.truetype(TTF, int(round(size * sc * SS)))
    width = sum(LAY['adv'][c] * size for c in s)
    pad = 12
    x0 = lay['x'] + (lay['w'] - width) * 0.5
    left = int(math.floor(x0 * sc)) - pad
    top = int(math.floor((lay['base'] - LAY['ascent'] * size) * sc)) - pad
    w = int(math.ceil(width * sc)) + 2 * pad
    h = int(math.ceil((LAY['ascent'] + LAY['descent']) * size * sc)) + 2 * pad
    big = Image.new('L', (w * SS, h * SS), 0)
    d = ImageDraw.Draw(big)
    pen = x0
    for c in s:
        d.text(((pen * sc - left) * SS, (lay['base'] * sc - top) * SS), c, font=font, fill=255, anchor='ls')
        pen += LAY['adv'][c] * size
    al = np.asarray(big.resize((w, h), Image.LANCZOS), dtype=np.float32) / 255.0
    return al, (-left, -top)


def glow(rgba, blur, strength, col, sc):
    """Flash GlowFilter (outer, quality 1) on a premultiplied float image, blur in Flash pixels (sc px each)"""
    a = rgba[..., 3]
    g = R.box_blur(a, blur * sc, blur * sc, 1)
    g = np.clip(g * strength, 0, 1)
    gl = np.stack([g * ((col >> 16) & 0xFF) / 255.0, g * ((col >> 8) & 0xFF) / 255.0, g * (col & 0xFF) / 255.0, g], axis=-1)
    return rgba + gl * (1 - rgba[..., 3:4])


def coloured(al, col):
    rgb = [int(col[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
    return np.stack([al * rgb[0], al * rgb[1], al * rgb[2], al], axis=-1)


# mcScore (Game.dispScore): field.text = the score, GlowFilter(2, 2, strength 5, white): the scores of the game
SCORE_LAY = field_layout(3, 2)
SCORES = [250, 400, 600, 800, 4000, 1000, 3000, 8000]
for v in SCORES:
    al, org = text_alpha(str(v), SCORE_LAY, 1.0)
    im = glow(coloured(al, SCORE_LAY['color']), 2, 5, 0xFFFFFF, K)
    img = Image.fromarray(np.clip(im * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
    E.pivots = pivots
    E.area = area
    E.write_anim('score%d' % v, [img], org)
    clips['score%d' % v] = dict(n=1, r=1.0, layers=[dict(k=0, a='score%d' % v, t=[1])])
meta['scores'] = SCORES

# mcLevelDisplay (Game.initStep(0)): field.text = "VAGUE " + n, the glyphs (white, tinted at run time) and the layout
WAVE_LAY = field_layout(20, 19)
CHARS = 'VAGUE 0123456789'
size = WAVE_LAY['size']
sc = K
font = ImageFont.truetype(TTF, int(round(size * sc * 4)))
pad = 3
gw = int(math.ceil(max(LAY['adv'][c] for c in CHARS) * size * sc)) + 2 * pad + 8
gh = int(math.ceil((LAY['ascent'] + LAY['descent']) * size * sc)) + 2 * pad + 2
ox, oy = pad + 1, pad + int(math.ceil(LAY['ascent'] * size * sc))
d = os.path.join(SRC, 'waveGlyphs')
os.makedirs(d, exist_ok=True)
a = 0
for i, ch in enumerate(CHARS):
    big = Image.new('L', (gw * 4, gh * 4), 0)
    ImageDraw.Draw(big).text((ox * 4, oy * 4), ch, font=font, fill=255, anchor='ls')
    al = big.resize((gw, gh), Image.LANCZOS)
    g = Image.new('RGBA', (gw, gh), (255, 255, 255, 0))
    g.putalpha(al)
    g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
    a += gw * gh
pivots['waveGlyphs'] = [round(ox / gw, 6), round(oy / gh, 6)]
area['waveGlyphs'] = a
meta['wave'] = dict(chars=CHARS, adv=[round(LAY['adv'][c] * size, 4) for c in CHARS], x=round(WAVE_LAY['x'], 4),
                    w=round(WAVE_LAY['w'], 4), base=round(WAVE_LAY['base'], 4), color=int(WAVE_LAY['color'][1:], 16))
print('wave', meta['wave'])

json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
