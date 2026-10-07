"""Builds the Spiroule graphics for KadoKadeo from the original SWF (gfx.swf of the archive folder Spirale: the
graphics library the released game.swf was compiled with, same shapes and timelines).

Every symbol the game attaches is exported as a Clip (timeline tables played by spiroule.Clip, see clipexport.py):
  - mcBg: the decor (bitmap shape 143, 300 x 300, non-smoothed fill) and `smc` (mcSpot: the alarm light, played by
    Game.danger);
  - mcLauncher: frame 1 the base (`smc`, the hole that recoils on a shot), frame 2 the turret (`gfx`, recoiling, and
    `smc`, the light whose alpha the code sets);
  - mcBall2: a ball of each colour (frame col + 1): its base disc, `smc` (where the game shows the texture bitmap of
    the ball) and its shading;
  - mcOnde, mcSideBurst, partEclat (`smc` coloured by the code), mcMulti (`smc` holds the text field "x<combo>",
    drawn by the game with the glyphs of the embedded Severina font).
Pictures composed here with what the code adds at run time (Flash filters and blend modes are in stage pixels):
  - fxSpark with its GlowFilter(10, 2, white) (Filt.glow of Runner / Ball.fxPart) for SPARK_STEPS scales: the clips
    shrink (Phys fadeType 0) and Flash blurs the shrunk clip by 10 stage pixels (anim "spark");
  - fxExplode with its GlowFilter(4, 1, white) at the scale the code shows it (120 %), anim "explode";
  - mcLoupiotes (blendMode "overlay" over the decor, nothing else under them): the overlay of each of the 5 lights on
    the decor, drawn by the game with the alpha of the timeline (anims "loupiote0..4", clips "mcLoupiotes0..4");
  - the textures of the balls (Game.initGfxTable: mcBallTexture drawn into 24 x 24 BitmapData, 48 positions of the
    rolling texture for each of the 5 colours): anims "tex0..4", 1 texture pixel per Flash pixel (attachBitmap
    without smoothing: drawn with the nearest pixel).
The non-smoothed bitmaps (decor, spot, ball textures) go to the second sheet "spirouleb" (bitmaps.json), sampled with
the nearest pixel by the game, like Flash 8 draws non-smoothed bitmap fills.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json, <out>/meta.json and <out>/bitmaps.json.
usage: spiroule_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/spiroule holds gfx.swf and its exports)
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

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'spiroule', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G1 = R.SWF(W + 'gfx.swf', W + 'shp1_gfx', Z=1)     # zoom 1: the bitmaps at their native resolution
G1.nearest = True
for X in (G, G1):
    X.flash_replace = True
K = C.K

# bitmap fills at scale 1 (FFDec SVG export: patternTransform scale 1): drawn from the zoom 1 export, 1 texture pixel
# per Flash pixel. 143 (decor) and 139 (spot) are non-smoothed fills (0x43): sheet "spirouleb"; the launcher's (123,
# 126, 128, 130) are smoothed (0x40)
BMP_SHAPES = [123, 126, 128, 130, 139, 143]
# their layers (named by the exporter after the character placed: shape 143, sprite 140 holding shape 139)
NEAREST_ANIMS = ['l143', 'l140']

# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM = {
    (70, 7): [['x', 'rmSelf']],         # mcOnde: removeMovieClip("")
    (32, 8): [['x', 'rmSelf']],         # mcSideBurst: removeMovieClip("")
    (120, 11): [['x', 'comptSet']],     # mcMulti: compt = 15
    (120, 13): [['x', 'comptLoop']],    # mcMulti: if (compt-- > 0) gotoAndPlay(_currentframe - 1)
    (120, 14): [['x', 'noFilters']],    # mcMulti: filters = [] (the glow of Chain.checkCombo)
    (120, 25): [['x', 'rmSelf']],       # mcMulti: removeMovieClip("")
}

E = C.Exporter(G, SRC, '', CUSTOM)
E.bitmaps = (G1, BMP_SHAPES)
E.clip_res = [0.5, 1.0, 1.5, 2.0]

# (cut: the decor stays one bitmap layer at its native resolution)
E.export(144, 'mcBg', code=('smc',), strategy='cut')
E.export(135, 'mcLauncher', code=('smc', 'gfx'))
E.export(67, 'mcBall2', code=('smc',))
E.export(70, 'mcOnde')
E.export(32, 'mcSideBurst')
E.export(103, 'partEclat', code=('smc',))
E.export(120, 'mcMulti', code=('smc',))

clips, pivots, area = E.clips, E.pivots, E.area
meta = {}


def nested(clip, name):
    ls = [Ly for Ly in clips[clip]['layers'] if Ly.get('nm') == name]
    assert len(ls) >= 1, (clip, name, ls)
    return ls[0]


for c, n in (('mcBg', 'smc'), ('mcLauncher', 'smc'), ('mcLauncher', 'gfx'), ('mcBall2', 'smc'), ('partEclat', 'smc'),
             ('mcMulti', 'smc')):
    Ly = nested(c, n)
    print('%s.%s: k=%d %s' % (c, n, Ly['k'], Ly['a']))


def layer_k(clip, name, sid, depth):
    """pixels of a named picture layer (k=1) per Flash pixel of the instance: the game draws into it (mcBall2.smc: the
    texture bitmap, mcMulti.smc: the text field)"""
    Ly = nested(clip, name)
    assert Ly['k'] == 1, Ly
    m = Ly['m0'] if 'm0' in Ly else Ly['m'][0]
    tl = [v for k, v in G.sprites[sid].frames[0] if k == 'place' and v['depth'] == depth][0]['matrix']
    return K * clips[clip]['r'] * tl['a'] / m[2]


meta['ballSmcK'] = round(layer_k('mcBall2', 'smc', 67, 2), 6)
meta['multiSmcK'] = round(layer_k('mcMulti', 'smc', 120, 1), 6)
print('smc pixels per Flash pixel: ball', meta['ballSmcK'], 'multi', meta['multiSmcK'])


def cmds_of(sid, ctrl=None, M=R.IDENT, cx=R.NOCX, g=None):
    g = g or G
    inst = R.Instance(g, sid, ctrl=dict(ctrl or {}, __noactions__=True))
    out = []
    R.Renderer(g, K).collect(inst, M, cx, set(), out)
    return out


def scale_m(s, tx=0.0, ty=0.0):
    return dict(R.IDENT, a=s, d=s, tx=tx, ty=ty)


def glow_rgba(im, blur_px, strength, color=(255, 255, 255)):
    """Flash's outer GlowFilter (quality 1: one box blur of blur_px x blur_px pixels of the picture) drawn under it"""
    a = np.asarray(im, dtype=np.float32) / 255.0
    al = a[..., 3]
    g = np.clip(R.box_blur(al, blur_px, blur_px, 1) * strength, 0, 1)
    # premultiplied: the picture over its glow
    src = a[..., :3] * al[..., None]
    gc = np.array(color, dtype=np.float32) / 255.0
    rgb = src + gc[None, None, :] * g[..., None] * (1 - al[..., None])
    alpha = al + g * (1 - al)
    out = np.zeros_like(a)
    nz = alpha > 0
    out[..., :3][nz] = rgb[nz] / alpha[nz][:, None]
    out[..., 3] = alpha
    return Image.fromarray(np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA')


# ---------------------------------------------------------------- fxSpark + GlowFilter(10, 2, white), by scale
# frame 1: the dot (shape 40) and its star (shape 41), frames 2..8: the dot. The code scales the clip (Runner:
# setScale(40..100), fadeType 0: x timer / 10 at the end): Flash draws the shrunk clip, then blurs it by 10 stage
# pixels. Pictures for SPARK_STEPS scales (k / SPARK_STEPS), the glow baked; the game shows the nearest one above the
# scale, shrunk to it
SPARK_STEPS = 24
cmds = []
for typ in (1, 2):
    for k in range(1, SPARK_STEPS + 1):
        cmds.append(cmds_of(42, {42: typ}, M=scale_m(k / SPARK_STEPS)))
imgs, reg = E.render(cmds, K, margin=8)
imgs = [glow_rgba(im, 10 * K, 2) for im in imgs]
E.write_anim('spark', imgs, reg)
meta['sparkSteps'] = SPARK_STEPS
# the timeline of fxSpark: frame 1 the star, 2..8 the dot (no script: it loops)
sd = G.sprites[42]
assert sd.nframes == 8 and not sd.actions, sd.actions
meta['sparkFrames'] = sd.nframes
# fxSpark itself: its playhead only (8 frames, looping); the game shows the picture of its frame and scale
clips['fxSpark'] = {'n': sd.nframes, 'r': 1.0, 'layers': []}

# ---------------------------------------------------------------- fxExplode + GlowFilter(4, 1, white) at 120 %
# Ball.explode: attach("fxExplode"), blendMode "add", Filt.glow(mc, 4, 1, 0xFFFFFF), _xscale = _yscale = 120. Drawn at
# 1.2 x 2 px per Flash pixel of the clip, the glow of 4 stage pixels = 4 x 2 texture pixels; the game shows it at 120 %
sd = G.sprites[97]
n = sd.nframes
EXR = 1.2
cmds = [cmds_of(97, {97: f}) for f in range(1, n + 1)]
imgs, reg = E.render(cmds, K * EXR, margin=4)
imgs = [glow_rgba(im, 4 * K, 1) for im in imgs]
# frame 27 removes the shape (and the clip)
assert not cmds[-1], 'fxExplode frame 27 should be empty'
E.write_anim('explode', imgs[:-1], reg)
clips['fxExplode'] = {'n': n, 'r': EXR, 'layers': [{'k': 0, 'a': 'explode', 't': list(range(1, n)) + [0]}],
                      'acts': {str(n): [['x', 'rmSelf']]}}

# ---------------------------------------------------------------- the light of the turret (mcLauncher frame 2, smc)
# sprite 134 placed with GlowFilter(5, 5, white, strength 1) and blendMode "overlay" over the turret and everything under
# it; the code sets its alpha (Game.updateLauncher). Drawn here with its glow, alone (clip "turretHl"): the game draws
# it into its overlay layer (OverlayLayer) and moves it with the turret
pl6 = [v for k, v in G.sprites[135].frames[1] if k == 'place' and v['depth'] == 6][0]
assert pl6.get('blend') == 'overlay' and pl6['filters'][0]['type'] == 'glow', pl6
gf = pl6['filters'][0]
assert gf['color'] == (255, 255, 255, 255) and gf['blurX'] == gf['blurY'] and gf.get('passes', 1) == 1, gf
imgs, reg = E.render([cmds_of(134)], K, margin=6)
imgs = [glow_rgba(imgs[0], gf['blurX'] * K, gf['strength'])]
E.write_anim('turretHl', imgs, reg)
m6 = pl6['matrix']
assert m6['a'] == 1 and m6['d'] == 1 and m6['b'] == 0 and m6['c'] == 0, m6
clips['turretHl'] = {'n': 1, 'r': 1.0, 'layers': [{'k': 1, 'a': 'turretHl', 't': [1], 'm0': [m6['tx'] * K, m6['ty'] * K, 1.0, 1.0, 0.0]}]}
# (out of mcLauncher's own pictures)
clips['mcLauncher']['layers'] = [Ly for Ly in clips['mcLauncher']['layers'] if not (Ly.get('nm') == 'smc' and Ly['k'] == 1)]
assert len(clips['mcLauncher']['layers']) == 2, clips['mcLauncher']['layers']
os.path.isdir(os.path.join(SRC, 'l134')) and shutil.rmtree(os.path.join(SRC, 'l134'))
for d_ in (E.area, E.pivots):
    d_.pop('l134', None)

# ---------------------------------------------------------------- mcMulti's blur (smc, frames 14..25, stage pixels)
blur = []
cur = 0.0
for f, ops in enumerate(G.sprites[120].frames, 1):
    for k, v in ops:
        if k == 'place' and v.get('depth') == 1 and v.get('filters') is not None:
            fl = [x for x in v['filters'] if x['type'] == 'blur']
            assert len(fl) == 1 and fl[0]['blurX'] == fl[0]['blurY'] and fl[0].get('passes', 1) == 1, v['filters']
            cur = fl[0]['blurX']
    blur.append(round(cur, 4))
meta['multiBlur'] = blur
print('multi blur', blur)

# ---------------------------------------------------------------- the decor bitmap (1 px per Flash pixel)
# its picture is read from the zoom 1 export of shape 143 (the 300 x 300 fill)
bg = np.asarray(Image.open(W + 'img_gfx/142.jpg').convert('RGB'), dtype=np.float32) / 255.0
assert bg.shape == (300, 300, 3)

# ---------------------------------------------------------------- mcLoupiotes over the decor ("overlay")
# Game.initBg: for i in 1, 3, 5, 7, 9: attach("mcLoupiotes", DP_BG) at (i * 9.5 - 1, 253), gotoAndPlay(16 - (i * 2) %
# 15), _fr = i == 9 ? 2 : 1 (sprite 28's frame script: gotoAndStop(_parent._fr)), blendMode "overlay". Frames 12..16
# show sprite 28 (white) at alpha 0.5 .. 0. Only the decor is under them: the overlay of white is min(2 x decor, 1),
# drawn with the coverage of the light x the alpha of the timeline (Flash: decor (1 - a) + overlay a). The decor is
# shown x2 with the nearest pixel: the picture is composed on the screen pixels.
sd29 = G.sprites[29]
assert sd29.nframes == 16
light = None
alphas = []
for f, ops in enumerate(sd29.frames, 1):
    for k, v in ops:
        if k == 'place' and v.get('depth') == 1:
            if not v.get('move'):
                light = v
            if v.get('cx'):
                alphas.append((f, v['cx']['mult'][3]))
al = {}
cur = None
for f in range(1, 17):
    for ff, a in alphas:
        if ff == f:
            cur = a
    al[f] = cur if f >= 12 else 0.0
print('loupiotes alpha', al, light['matrix'])
bgx2 = np.repeat(np.repeat(bg, K, axis=0), K, axis=1)
# (the first light sticks out of the stage on the left: nothing is shown there)
BP = 32
bgx2 = np.pad(bgx2, ((BP, BP), (BP, BP), (0, 0)))
LOUPS = [1, 3, 5, 7, 9]
for li, i in enumerate(LOUPS):
    fr = 2 if i == 9 else 1
    x0, y0 = i * 9.5 - 1, 253
    m = light['matrix']
    M = dict(R.IDENT, a=m['a'], b=m['b'], c=m['c'], d=m['d'], tx=x0 + m['tx'], ty=y0 + m['ty'])
    cm = cmds_of(28, {28: fr}, M=M)
    rd = R.Renderer(G, K)
    bb = rd.bounds(cm)
    ox, oy = math.floor(bb[0] - 1), math.floor(bb[1] - 1)
    ex, ey = math.ceil(bb[2] + 1), math.ceil(bb[3] + 1)
    canvas = np.zeros((int((ey - oy) * G.Z), int((ex - ox) * G.Z), 4), dtype=np.float32)
    rd.draw(cm, canvas, (ox, oy))
    im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa')
    im = im.resize((int((ex - ox) * K), int((ey - oy) * K)), Image.LANCZOS).convert('RGBA')
    a = np.asarray(im, dtype=np.float32) / 255.0
    assert np.all(a[..., :3][a[..., 3] > 0.05] > 0.98), 'the light should be white'
    cov = a[..., 3]
    sub = bgx2[int(oy * K) + BP:int(ey * K) + BP, int(ox * K) + BP:int(ex * K) + BP]
    ov = np.minimum(sub * 2, 1.0)
    rgba = np.zeros(cov.shape + (4,), dtype=np.float32)
    rgba[..., :3] = ov
    rgba[..., 3] = cov
    pic = Image.fromarray(np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA')
    name = 'loupiote%d' % li
    # pivot: the clip's origin (x0, y0)
    E.write_anim(name, [pic], ((x0 - ox) * K, (y0 - oy) * K))
    # (a picture moved by a matrix, not a flat layer: Clip applies the alpha table to those)
    clips['mcLoupiotes%d' % li] = {'n': 16, 'r': 1.0, 'layers': [
        {'k': 1, 'a': name, 't': [1 if f >= 12 else 0 for f in range(1, 17)], 'm0': [0.0, 0.0, 1.0, 1.0, 0.0],
         'al': [round(al[f], 4) for f in range(1, 17)]}]}
meta['loupiotes'] = LOUPS

# ---------------------------------------------------------------- textures of the balls (Game.initGfxTable)
# mcBallTexture: shape 54 (disc of radius 11) masks smc (mcBallText: the texture of colour i + 1, a 48 x 24 bitmap
# placed at x = 0, 48 and -48, non-smoothed fill), smc._x = fr - 60 (fr = 0..47), smc._y = -12.15 (its place). Drawn
# with translate(12, 12) into a 24 x 24 BitmapData: pixel (px, py) is the point (px + 0.5 - 12, py + 0.5 - 12) of the
# clip; the texture's pixel there (nearest), times the coverage of the disc (antialiased at 16 x 16 samples)
sd55 = G.sprites[55]
pl = {v['depth']: v for k, v in sd55.frames[0] if k == 'place'}
assert pl[1]['clip'] is not None if 'clip' in pl[1] else True
smc_ty = pl[2]['matrix']['ty']
print('mcBallTexture smc ty', smc_ty, 'mask', pl[1].get('clip'))
TEX_BMP = [43, 45, 47, 49, 51]
SS = 16
yy, xx = np.mgrid[0:24 * SS, 0:24 * SS]
px = (xx + 0.5) / SS - 12
py = (yy + 0.5) / SS - 12
# shape 54: a disc of radius 11 centred on 0 (its bounds [-11, 11])
disc = (px * px + py * py <= 11 * 11).astype(np.float32)
cov = disc.reshape(24, SS, 24, SS).mean(axis=(1, 3))
gy, gx = np.mgrid[0:24, 0:24]
cx_ = gx + 0.5 - 12
cy_ = gy + 0.5 - 12
TEXN = []
for i, bid in enumerate(TEX_BMP):
    tex = np.asarray(Image.open(W + 'img_gfx/%d.%s' % (bid, 'jpg' if bid == 43 else 'png')).convert('RGB'), dtype=np.float32) / 255.0
    assert tex.shape == (24, 48, 3), tex.shape
    imgs = []
    for fr in range(48):
        sx = fr / 48 * 48 - 60
        u = np.floor(cx_ - sx).astype(int) % 48
        v = np.floor(cy_ - smc_ty).astype(int)
        assert v.min() >= 0 and v.max() < 24
        rgba = np.zeros((24, 24, 4), dtype=np.float32)
        rgba[..., :3] = tex[v, u]
        rgba[..., 3] = cov
        imgs.append(Image.fromarray(np.clip(rgba * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA'))
    E.write_anim('tex%d' % i, imgs, (0, 0))
    TEXN.append('tex%d' % i)


# ---------------------------------------------------------------- mcMulti's text field: Severina digits
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


GLYPHS = 'x0123456789'
FONTS = font_layouts(W + 'gfx.swf')
TTF = W + 'fonts_gfx/117_Severina.ttf'
TX = swftext.all_edittexts(W + 'gfx.swf')
t = TX[118]
assert t['font'] == 117 and t['align'] == 'center' and t['color'] == '#ffffff' and not t['html'], t
lay = FONTS[117]
assert set(GLYPHS) <= set(lay['adv']), lay['adv']
size = t['height']
# the field in sprite 119 (smc of mcMulti): placed at (-21, -14), bounds [-2, 44, -2, 30]
sd119 = G.sprites[119]
e119 = [v for k, v in sd119.frames[0] if k == 'place'][0]
m = e119['matrix']
assert m['a'] == 1 and m['d'] == 1 and m['b'] == 0 and m['c'] == 0, m
asc = lay['ascent'] * size
field = dict(x=round(m['tx'] + t['bounds'][0] + 2, 3), w=round(t['bounds'][1] - t['bounds'][0] - 4, 3),
             base=round(m['ty'] + t['bounds'][2] + 2 + asc, 3))
print('multi field', field, 'size', size, t)

# glyphs: white, pivot on the pen position of the baseline; drawn at the resolution of smc's pictures (the field is
# shown up to 113 % x 300 % of the clip (combo 10): at 2 x K px per Flash pixel)
GRES = 2.0
SSG = 4
sc = K * GRES
font = ImageFont.truetype(TTF, int(round(size * sc * SSG)))
pad = 2
gw = int(math.ceil(max(lay['adv'][c] for c in GLYPHS) * size * sc)) + 2 * pad + 8
gh = int(math.ceil((lay['ascent'] + lay['descent']) * size * sc)) + 2 * pad + 4
ox, oy = pad + 2, pad + int(math.ceil(lay['ascent'] * size * sc))
gl = []
for ch in GLYPHS:
    big = Image.new('L', (gw * SSG, gh * SSG), 0)
    ImageDraw.Draw(big).text((ox * SSG, oy * SSG), ch, font=font, fill=255, anchor='ls')
    a = big.resize((gw, gh), Image.LANCZOS)
    im = Image.new('RGBA', (gw, gh), (255, 255, 255, 0))
    im.putalpha(a)
    gl.append(im)
E.write_anim('multiDig', gl, (ox, oy))
meta['multiField'] = field
meta['multiAdv'] = [round(lay['adv'][c] * size, 4) for c in GLYPHS]
meta['multiGlyphRes'] = GRES

# ---------------------------------------------------------------- output
assert all(a in E.area for a in NEAREST_ANIMS), [a for a in E.area if a.startswith('l')]
BITMAPS = sorted(set(TEXN) | set(NEAREST_ANIMS))
# the anims of the non-smoothed bitmap layers (named after their shape by the exporter)
for nm, cd in clips.items():
    for Ly in cd['layers']:
        if Ly['k'] != 2:
            print('  %s layer k=%d %s' % (nm, Ly['k'], Ly['a']))
print('bitmaps (nearest sheet)', BITMAPS)
json.dump(BITMAPS, open(os.path.join(OUT, 'bitmaps.json'), 'w'))
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
