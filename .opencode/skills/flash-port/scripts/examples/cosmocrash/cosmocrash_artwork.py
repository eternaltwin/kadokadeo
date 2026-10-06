"""Start screen of Cosmo Crash (public/assets/img/gfx/artwork/cosmocrash.jpg, 600 x 600) composed from SWF renders: a
moment of a game as the code places it (there is no old thumbnail of the game: the layout follows the screenshots of
the archive, sc/sc1.jpg): the screen above the hero's platform (camera at x 1699, y 150), the sky of mcBg's 10 x 10
bitmap, the horizon and its mountains, the ground of the level (the tiles of cosmocrash_assets.py), the platform with
its shuttle and counter, the hero thrusting, colonists on the ground and one jumping, a tank aiming at the hero (its
black outline, Filt.glow(root, 2, 4, 0)) and the gyroscope (green, white glow, added).
usage: cosmocrash_artwork.py <out dir of cosmocrash_assets.py> <out jpg>"""
import os, sys, math, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image
import swfrender as R
import cosmocrash_level as L

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'cosmocrash', '')
OUT, DST = sys.argv[1], sys.argv[2]
G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
G.nested_masks = True
Z = G.Z
K = 2
meta = json.load(open(os.path.join(OUT, 'meta.json')))
pivots = json.load(open(os.path.join(OUT, 'pivots.json')))
CX, CY = 1699, 150                     # the camera: the hero's platform (x 1849) in the middle
top, plats, _ = L.level()


def gy(x):
    px = int(x / L.PW)
    c = x / L.PW - px
    return L.LH - int((top[px] * (1 - c) + top[(px + 1) % L.PMAX] * c) * L.EC)


canvas = np.zeros((300 * Z, 300 * Z, 4), dtype=np.float32)


def comp(layer, blend=None):
    global canvas
    if blend == 'add':
        canvas = np.clip(canvas + layer * np.array([1, 1, 1, 0], dtype=np.float32), 0, 1)
        canvas[..., 3] = np.maximum(canvas[..., 3], 1)
        return
    canvas *= (1 - layer[..., 3:4])
    canvas += layer


def cmds_of(sid, ctrl, M, cx=R.NOCX, edit=None):
    c = dict(ctrl)
    c.setdefault(sid, 1)
    c['__noactions__'] = True
    inst = R.Instance(G, sid, ctrl=c)
    if edit:
        edit(inst)
    out = []
    R.Renderer(G, K).collect(inst, M, cx, set(), out)
    return out


def mat(x, y, sx=1.0, sy=None, rot=0.0):
    sy = sx if sy is None else sy
    r = math.radians(rot)
    return dict(a=sx * math.cos(r), b=sx * math.sin(r), c=-sy * math.sin(r), d=sy * math.cos(r), tx=x, ty=y)


def draw(cmds, filt=None, blend=None):
    lay = np.zeros_like(canvas)
    R.Renderer(G, K).draw(cmds, lay, (0, 0))
    if filt:
        lay = R.apply_filter(lay, filt, Z)
    comp(lay, blend)


def paste_png(path, x, y, pivot=(0, 0)):
    """an exported picture (x2) with its pivot at (x, y) Flash pixels of the screen"""
    im = Image.open(path).convert('RGBA')
    big = im.resize((im.width * Z // K, im.height * Z // K), Image.LANCZOS)
    a = np.asarray(big, dtype=np.float32) / 255.0
    lay = np.zeros_like(canvas)
    ox = int(round(x * Z - pivot[0] * big.width))
    oy = int(round(y * Z - pivot[1] * big.height))
    h, w = a.shape[:2]
    x0, y0, x1, y1 = max(0, ox), max(0, oy), min(lay.shape[1], ox + w), min(lay.shape[0], oy + h)
    if x1 <= x0 or y1 <= y0:
        return
    s = a[y0 - oy:y1 - oy, x0 - ox:x1 - ox]
    lay[y0:y1, x0:x1] = np.concatenate([s[..., :3] * s[..., 3:4], s[..., 3:4]], axis=-1)
    comp(lay)


# the sky: mcBg's 10 x 10 bitmap at 3000 %, not smoothed
bg = np.array(meta['bg'], dtype=np.int64).reshape(10, 10)
for j in range(10):
    for i in range(10):
        c = bg[j, i]
        canvas[j * 30 * Z:(j + 1) * 30 * Z, i * 30 * Z:(i + 1) * 30 * Z] = [((c >> 16) & 255) / 255, ((c >> 8) & 255) / 255, (c & 255) / 255, 1]
# stars (mcStar: 1 px squares)
rs = np.random.RandomState(7)
draw([c for i in range(25) for c in cmds_of(42, {}, mat(rs.rand() * 300, rs.rand() * 200))])
# the horizon (mcHor at 220, smc at 120 - c * 54 % for the camera at the bottom of the map) and its decor
h = 120 - (CY / (L.LH - 300)) * 54
draw(cmds_of(204, {}, mat(0, 220), edit=lambda inst: [e.update(matrix=dict(e['matrix'], d=h / 100.0))
                                                         for e in inst.display.values() if e['name'] == 'smc']))
for i, x in ((0, 70), (1, 230), (2, 150), (3, 280), (8, 40), (14, 200), (21, 120), (30, 260)):
    c = 0.05 + (i / 40.0) * 0.95
    draw(cmds_of(105, {105: i + 1, 104: i + 1}, mat(x, 220 + c * h)))

# the map, in the order of its planes: platforms 4, hero 6, vehicles 8, ground 12, colonists 13, shots and particles 14
# the platform (Plat.new: ray 50, its ramp at rampeX, the shuttle on "bat", the counter on 3)
px, py, ray, rx = plats[1]


def plat_parts(inst):
    for e in inst.display.values():
        m = e['matrix']
        n = e['name']
        if n in ('base', 'shade'):
            e['matrix'] = dict(m, a=(ray * 2 - 20) / 100.0)
        elif n == 'right':
            e['matrix'] = dict(m, tx=ray - 10)
        elif n == 'left':
            e['matrix'] = dict(m, tx=10 - ray)
        elif n == 'pil0':
            e['matrix'] = dict(m, tx=-(ray - 15))
        elif n == 'pil1':
            e['matrix'] = dict(m, tx=ray - 15)
        elif n == 'rampe':
            e['matrix'] = dict(m, tx=rx)


draw(cmds_of(185, {'shuttle': 29, 'digit': 4}, mat(px - CX, py - CY), edit=plat_parts))
# the hero thrusting (flames shown), turned like Hero.turn (steps of 10 degrees)
draw(cmds_of(81, {81: 1, '_reac0': 2, '_reac1': 3}, mat(145, 55, rot=-20)))
# the tank (type 1: back, wheels, canon aiming up left, body), with its outline
tx = 1735
ty = gy(tx) - 5
tank = []
tank += cmds_of(24, {24: 4}, mat(tx - CX + 9, ty - CY))
for wx in (0, 18):
    tank += cmds_of(30, {}, mat(tx - CX + wx, ty - CY))
tank += cmds_of(28, {}, mat(tx - CX + 9, ty - CY - 16, rot=-125))
tank += cmds_of(24, {24: 3}, mat(tx - CX + 9, ty - CY))
draw(tank, filt=dict(type='glow', blurX=2, blurY=2, strength=4, color=(0, 0, 0, 255), passes=1))
# the ground (the tiles of bmpLevel)
for t in range(meta['ground']['n']):
    paste_png(os.path.join(OUT, 'src', 'ground', '%d.png' % (t + 1)), t * meta['ground']['tile'] - CX, meta['ground']['y0'] - CY)
# colonists on the ground (white, a blue one sitting), a green one jumping to the hero ("jump"): the pictures of the
# colour copies of mcFolk
clips = json.load(open(os.path.join(OUT, 'clips.json')))


def folk(k, f, x, y, flip=False):
    name = 'mcFolk' + ('%d' % k if k else '')
    t = clips[name]['layers'][0]['t'][f - 1]
    im = os.path.join(OUT, 'src', name + '_0', '%d.png' % t)
    pv = pivots[name + '_0']
    if flip:
        flipped = os.path.join(W, 'art_flip.png')
        Image.open(im).transpose(Image.FLIP_LEFT_RIGHT).save(flipped)
        im, pv = flipped, (1 - pv[0], pv[1])
    paste_png(im, x, y, pv)


for x, k, f, flip in ((1745, 0, 6, False), (1782, 2, 46, False), (1905, 0, 11, True)):
    folk(k, f, x - CX, gy(x) - CY, flip)
folk(1, 20, 112, 92)
# a shell of the tank, sparks of the thrust
draw(cmds_of(51, {51: 2}, mat(70, 70)))
for i in range(10):
    draw(cmds_of(60, {60: 1, 59: 14 + 2 * i}, mat(150 + rs.randn() * 6 + i * 1.5, 72 + i * 4 + rs.randn() * 3)))

# the gyroscope: glow 8 / 1.2 (white), coloured green with the pictures (Col.setColor: Flash applies the colour
# transform after the filters), added
draw(cmds_of(72, {'vector': 30}, mat(284, 16), cx=dict(mult=[0.0, 1.0, 0.0, 1.0], add=[0, 0, 0, 0])),
     filt=dict(type='glow', blurX=8, blurY=8, strength=1.2, color=(0, 255, 0, 255), passes=1), blend='add')

im = Image.fromarray(np.clip(canvas * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBa').convert('RGBA')
im = im.resize((600, 600), Image.LANCZOS).convert('RGB')
im.save(DST, quality=90)
print(DST)
