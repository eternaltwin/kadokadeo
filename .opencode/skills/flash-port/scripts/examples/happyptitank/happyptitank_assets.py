"""Happy Pti Tank: tank.swf (the graphics library linked into game.swf, AS3) -> leaf pictures + timeline tables.

The game is a Flash 9 (AS3) game: its classes are bound to library symbols and drive them as an AS3 display list
(addChild, x / y / rotation / scaleX / alpha, gotoAndStop, timelines that play on their own). The port keeps that
display list in the game (Display.hx) and only asks PIXI to draw it, so the export is not flattened: every symbol is
a table of its frames (display list per frame) and every shape / static text is a leaf picture drawn with the
matrices of the timelines and of the code. The game reads the display for its gameplay (pixel-precise collisions
of Collision.isColliding, getBounds, width / height, getRect): each leaf also carries its bounds (the SWF's, the
way Flash computes getBounds) and a collision mask (4 samples per Flash pixel).

What PIXI cannot draw as a plain leaf is baked here, from the SWF:
  - the tank's body (col2 in 'overlay') and canon (col3 in 'overlay'), coloured by the code with one of the 9
    colours of ColorSet: one picture per colour (variant);
  - the shot (col1 in 'hardlight', coloured by the code) over its blinking core (sprite 155): one picture per
    frame of the core and per colour;
  - OptShotRate (three 'hardlight' dots of fixed colours);
  - the tracks (TankTracks: a scrolling tread under a mask): one picture per frame;
  - the glow under the tank (sprite 165: 201 frames of a blurred bar), drawn white (col1, coloured by the code).
Kept for the run time (Display.hx): the masks and the blurs / glows of the end animations and the zone banner.

usage: happyptitank_assets.py <out dir>   (after prepare_game.sh + zoom 8 and text exports, see rebuild_assets.sh)
Writes <out>/src/<leaf>/0.png (+ tiles of the big ones), <out>/pivots.json, <out>/data.json.
"""
import os, sys, json, math, base64, shutil
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'happyptitank', '')
OUT = sys.argv[1] if len(sys.argv) > 1 else W + 'out'
SRC = os.path.join(OUT, 'src')

G = R.SWF(W + 'tank.swf', W + 'shp4_tank', Z=4)
G.flash_replace = True
G.svg_dir = W + 'svg_tank'
RD = R.Renderer(G, 4)

# classes bound to the symbols (SymbolClass tag of tank.swf)
CLASSES = {226: 'Texture2', 225: 'Texture1', 224: 'EnemyShot', 218: 'Target', 213: 'OptTime', 211: 'OptSpeed',
           209: 'OptArmor', 207: 'OptShot', 205: 'OptShotRate', 200: 'Fireworks', 199: 'XLink', 197: 'XBall',
           186: 'WarZone', 181: 'Tank', 180: 'TankCanon', 162: 'TankTracks', 158: 'Shot', 150: 'Spawner',
           148: 'Mine', 142: 'Foe', 134: 'FoeBack', 132: 'DummyFoe', 120: 'XMissileCross', 118: 'XMissile',
           114: 'Lazer', 110: 'UserInterface', 97: 'OptTimer', 93: 'ArmorBit', 91: 'ZoneCleared',
           88: 'IncomingArrow', 86: 'ColorSet', 84: 'FlyPaper', 73: 'Nature', 62: 'Warning', 54: 'Rainbow1',
           41: 'TheEnd', 32: 'YouDie', 27: 'Miner', 6: 'Rainbow', 4: 'BgCenter'}
# the symbols the game uses (Fireworks, ZoneCleared, Rainbow are never instantiated; ColorSet only gives colours)
ROOTS = [224, 218, 213, 211, 209, 207, 205, 199, 197, 186, 181, 162, 158, 150, 148, 142, 134, 132, 120, 118, 114,
         110, 93, 88, 84, 73, 62, 54, 41, 32, 27, 4]

# ColorSet (symbol 86): the 9 squares of 10 x 10 read by getPixel(5 + 10 n, 5)
PALETTE = [0xfe6945, 0xfeb74e, 0xfeed56, 0xccfe56, 0x81fe99, 0x3eb0fd, 0xa681fe, 0xc570fe, 0xff99cc]

# scale the code gives some symbols on top of their timelines (texture resolution of their leaves)
CODE_SCALE = {
    73: 4.5,    # Nature: scaleMax = 0.5 * speed, speed < (1.5 + 3) * 60 / 30 (EnemyDeathAnim)
    84: 2.0,    # FlyPaper: scale up to 2 (FlyPaperAnim)
    118: 1.6,   # XMissile: scaleY = 1 + 2 * (1 - elap) when it starts to fall (then nearly transparent)
}

# symbols whose leaves the code tints with an offset (Tank.setState Hurt / Heal, HurtAnim on every Enemy) or whose
# timeline does (the ticks of OptTimer: multiplier + offset): they get a white picture too (drawn ADD and tinted with
# the offset)
WHITE_ROOTS = [181, 142, 132, 27, 197, 199, 97]

# symbols the gameplay tests pixel by pixel (Collision.isColliding(.., true)) or by bounds: their leaves get a mask
MASK_ROOTS = [181, 142, 132, 27, 197, 199, 148, 224, 114, 213, 211, 209, 207, 205]

os.makedirs(SRC, exist_ok=True)
pivots = {}
leaves = {}        # leaf name -> dict
WARN = []


def warn(s):
    WARN.append(s)
    print('WARN', s)


# ---------------------------------------------------------------- timelines (display list per frame)
def entry(d, f, char):
    return dict(key=d * 1000 + f, depth=d, char=char, matrix=R.IDENT, cx=R.NOCX, name=None, clip=None, filters=[],
                blend=None)


def frame_lists(sid):
    """the display list of each frame of a sprite: entries sorted by depth. key = depth * 1000 + frame of the
    placement that created the instance: an instance is the same object in two frames when its key is the same
    (Flash keeps the object, and its own playhead, while the timeline does not replace it)"""
    sd = G.sprites[sid]
    disp = {}
    out = []
    for f in range(1, sd.nframes + 1):
        for kind, v in sd.frames[f - 1]:
            if kind == 'remove':
                disp.pop(v, None)
                continue
            d = v['depth']
            e = disp.get(d)
            if 'char' in v and not (e is not None and v['move'] and e['char'] == v['char']):
                if e is not None and v['move']:
                    # a character replaced at a used depth keeps the matrix / colour of the previous one
                    e = dict(e, char=v['char'], key=d * 1000 + f)
                else:
                    e = entry(d, f, v['char'])
                disp[d] = e
            if e is None:
                continue
            e = dict(e)
            disp[d] = e
            for k in ('matrix', 'cx', 'name', 'filters', 'blend'):
                if k in v:
                    e[k] = v[k]
            if 'clipDepth' in v:
                e['clip'] = v['clipDepth']
        out.append([dict(disp[d]) for d in sorted(disp)])
    return out


def kind_of(c):
    if c in G.sprites:
        return 'sprite'
    if c in G.shapes:
        return 'shape'
    if c in G.texts:
        return 'edit'
    return 'text'


# ---------------------------------------------------------------- static texts (DefineText): bounds
import swfdump as SD
import zlib, struct


def read_text_bounds(path):
    raw = open(path, 'rb').read()
    data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
    b = SD.Bits(data, 8)
    b.rect(); b.u16(); b.u16()
    out, edge = {}, {}
    for code, body in SD.read_tags(data, b.pos, len(data)):
        if code in (11, 33):
            bb = SD.Bits(body)
            cid = bb.u16()
            out[cid] = bb.rect()
        elif code == 83:   # DefineShape4: shape bounds, then edge bounds (getRect)
            bb = SD.Bits(body)
            cid = bb.u16()
            bb.rect()
            edge[cid] = bb.rect()
    return out, edge


TEXT_BOUNDS, EDGE_BOUNDS = read_text_bounds(W + 'tank.swf')
EDITS = swftext.all_edittexts(W + 'tank.swf')


# ---------------------------------------------------------------- reachability, scales
def walk(sid, M, fn, seen_depth=0):
    """every leaf placement under a sprite, with its matrix from the sprite (all frames)"""
    for fl in frame_lists(sid):
        for e in fl:
            m = R.mat_mul(M, e['matrix'])
            c = e['char']
            if c in G.sprites:
                if seen_depth < 12:
                    walk(c, m, fn, seen_depth + 1)
            else:
                fn(c, m, e)


def mscale(m):
    sx = math.hypot(m['a'], m['b'])
    sy = math.hypot(m['c'], m['d'])
    return max(sx, sy)


_reach_cache = {}


def reach_leaves(sid):
    if sid in _reach_cache:
        return _reach_cache[sid]
    s = {}

    def fn(c, m, e):
        s[c] = max(s.get(c, 0), mscale(m))
    walk(sid, R.IDENT, fn)
    _reach_cache[sid] = s
    return s


# ---------------------------------------------------------------- picture helpers
def save_leaf_png(name, im, ox, oy, res):
    """a leaf picture: im covers Flash units from (ox, oy) at res pixels per unit"""
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, '0.png'))
    pivots[name] = [round(-ox * res / im.width, 6), round(-oy * res / im.height, 6)]


def white_of(im):
    a = np.asarray(im.convert('RGBA')).copy()
    a[..., :3] = 255
    a[a[..., 3] == 0] = 0
    return Image.fromarray(a, 'RGBA')


def pad_to(im, k):
    w = (im.width + k - 1) // k * k
    h = (im.height + k - 1) // k * k
    if (w, h) == im.size:
        return im
    c = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    c.paste(im, (0, 0))
    return c


def reduce_premult(im, k):
    """box reduction by an integer factor, in premultiplied colour (no dark fringes)"""
    if k == 1:
        return im
    a = np.asarray(im.convert('RGBA'), dtype=np.float64) / 255.0
    a[..., :3] *= a[..., 3:4]
    h, w = a.shape[0] // k, a.shape[1] // k
    a = a[:h * k, :w * k].reshape(h, k, w, k, 4).mean(axis=(1, 3))
    rgb = np.where(a[..., 3:4] > 0, a[..., :3] / np.maximum(a[..., 3:4], 1e-9), 0)
    out = np.concatenate([rgb, a[..., 3:4]], axis=-1)
    return Image.fromarray(np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA')


MASKS = []
mask_index = {}


def mask_bits(alpha, thr=8):
    """collision mask (1 = the pixel is drawn, at 4 per Flash pixel): index in MASKS, where each mask is
    {w, h, rle}: per row, the lengths of the runs (empty first, then drawn, alternately; each run as a byte, 255 =
    255 more of the same run followed by another byte), base64"""
    m = alpha >= thr
    h, w = m.shape
    out = bytearray()
    for y in range(h):
        row = m[y]
        runs = []
        cur, n = False, 0
        for v in row:
            if v == cur:
                n += 1
            else:
                runs.append(n)
                cur, n = v, 1
        runs.append(n)
        out.append(len(runs) - 1 if len(runs) - 1 < 255 else 255)
        assert len(runs) - 1 < 255
        for r in runs[:-1]:
            while r >= 255:
                out.append(255)
                r -= 255
            out.append(r)
    k = (int(w), int(h), bytes(out))
    if k not in mask_index:
        mask_index[k] = len(MASKS)
        MASKS.append(dict(w=int(w), h=int(h), rle=base64.b64encode(bytes(out)).decode('ascii')))
    return mask_index[k]


TILE = 128
BIG = 520
# the shapes of the masks of Rainbow1 (clipDepth): PIXI masks with one picture, never tiled
MASK_SHAPES = {'S42', 'S47'}


def emit_leaf(name, im, ox, oy, res, white=False, mask_im=None, mask_o=None, bounds=None, rect=None):
    """registers a leaf: picture (tiled when big), white copy, mask (4 px per unit), bounds"""
    L = dict(res=res, ox=ox, oy=oy, w=im.width / res, h=im.height / res)
    if (im.width > BIG or im.height > BIG) and name not in MASK_SHAPES:
        # big and mostly empty pictures (frames, borders): tiles of TILE pixels, the empty ones dropped
        tiles = []
        a = np.asarray(im)[..., 3]
        for ty in range(0, im.height, TILE):
            for tx in range(0, im.width, TILE):
                if a[ty:ty + TILE, tx:tx + TILE].max() == 0:
                    continue
                tn = '%s_%d_%d' % (name, tx // TILE, ty // TILE)
                save_leaf_png(tn, im.crop((tx, ty, min(im.width, tx + TILE), min(im.height, ty + TILE))),
                              ox + tx / res, oy + ty / res, res)
                tiles.append(tn)
        L['tiles'] = tiles
        if white:
            warn('white copy of a tiled leaf %s ignored' % name)
    else:
        save_leaf_png(name, im, ox, oy, res)
        if white:
            save_leaf_png(name + '_w', white_of(im), ox, oy, res)
            L['white'] = True
            # Config.addGroundShadow: DropShadowFilter(1, 45, black, alpha 2 (1), blur 2 x 2, quality 1) on the
            # same objects: the picture's alpha blurred by a box of 2 Flash pixels, in black (drawn under the object
            # by the game, 1 pixel down-right in stage pixels)
            pad = 2 * res
            a = np.zeros((im.height + 2 * pad, im.width + 2 * pad), dtype=np.float64)
            a[pad:pad + im.height, pad:pad + im.width] = np.asarray(im)[..., 3] / 255.0
            a = R.box_blur(a, 2 * res, 2 * res, 1)
            sh = np.zeros(a.shape + (4,), dtype=np.uint8)
            sh[..., 3] = np.clip(a * 255 + 0.5, 0, 255).astype(np.uint8)
            save_leaf_png(name + '_s', Image.fromarray(sh, 'RGBA'), ox - pad / res, oy - pad / res, res)
    if mask_im is not None:
        L['mask'] = mask_bits(np.asarray(mask_im.convert('RGBA'))[..., 3])
        L['mox'], L['moy'] = mask_o
    if bounds is not None:
        L['b'] = [round(v, 3) for v in bounds]
    if rect is not None:
        L['r'] = [round(v, 3) for v in rect]
    leaves[name] = L
    return name


def choose_res(scale):
    need = 2 * scale
    for r in (2, 4, 8):
        if need <= r * 1.15:
            return r
    return 8


def shape_png(cid, zoom):
    folder = {1: 'shp1_tank', 4: 'shp4_tank', 8: 'shp8_tank'}[zoom]
    return Image.open(os.path.join(W, folder, '%d.png' % cid)).convert('RGBA')


def text_png(cid, zoom):
    import subprocess, io
    r = subprocess.run(['rsvg-convert', '-z', str(zoom), os.path.join(W, 'txtsvg_tank', '%d.svg' % cid)],
                       capture_output=True, check=True)
    return Image.open(io.BytesIO(r.stdout)).convert('RGBA')


def leaf_for_char(c, scale, white, mask):
    name = ('S%d' if c in G.shapes else 'T%d') % c
    if name in leaves:
        L = leaves[name]
        if (white and not L.get('white')) or (mask and 'mask' not in L) or choose_res(scale) > L['res']:
            del leaves[name]
        else:
            return name
    res = choose_res(scale)
    if c in G.shapes:
        x0, x1, y0, y1 = G.shapes[c]
        src = shape_png(c, 8)
        im = reduce_premult(pad_to(src, 8 // res), 8 // res)
        mim = reduce_premult(pad_to(src, 2), 2) if mask else None
        rect = EDGE_BOUNDS.get(c, G.shapes[c])
        return emit_leaf(name, im, x0, y0, res, white, mim, (x0, y0), [x0, x1, y0, y1], list(rect))
    x0, x1, y0, y1 = TEXT_BOUNDS[c]
    im = text_png(c, res)
    mim = text_png(c, 4) if mask else None
    return emit_leaf(name, im, x0, y0, res, white, mim, (x0, y0), [x0, x1, y0, y1], [x0, x1, y0, y1])


# ---------------------------------------------------------------- baked composites
def collect_depths(inst, keep):
    """draw commands of an instance, only the depths kept (keep(depth) -> bool)"""
    saved = inst.display
    inst.display = {d: e for d, e in saved.items() if keep(d)}
    cmds = []
    RD.collect(inst, R.IDENT, R.NOCX, set(), cmds)
    inst.display = saved
    return cmds


def canvas_for(cmd_lists, margin=1.0):
    bb = None
    for cmds in cmd_lists:
        b = RD.bounds(cmds)
        if b:
            bb = b if bb is None else (min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3]))
    ox = math.floor(bb[0] - margin)
    oy = math.floor(bb[1] - margin)
    ex = math.ceil(bb[2] + margin)
    ey = math.ceil(bb[3] + margin)
    return (ox, oy, ex, ey)


def draw_z4(cmds, box):
    ox, oy, ex, ey = box
    c = np.zeros((int((ey - oy) * 4), int((ex - ox) * 4), 4), dtype=np.float32)
    RD.draw(cmds, c, (ox, oy))
    return c


def to_image(premul, k):
    """premultiplied float at 4 px per unit -> RGBA picture at 4 / k px per unit"""
    a = premul
    h, w = a.shape[0] // k, a.shape[1] // k
    a = a[:h * k, :w * k].reshape(h, k, w, k, 4).mean(axis=(1, 3))
    rgb = np.where(a[..., 3:4] > 0, a[..., :3] / np.maximum(a[..., 3:4], 1e-9), 0)
    out = np.concatenate([np.clip(rgb, 0, 1), np.clip(a[..., 3:4], 0, 1)], axis=-1)
    return Image.fromarray((out * 255 + 0.5).astype(np.uint8), 'RGBA')


def blend_flash(base, layer, mode, color=None):
    """Flash 'overlay' / 'hardlight' of a layer over an opaque-ish base (premultiplied arrays); color: the solid
    colour the code gives the layer (ColorSet.setColor: multiplier 0, offset = colour)"""
    la = layer[..., 3:4]
    if color is not None:
        s = np.array([((color >> 16) & 255) / 255, ((color >> 8) & 255) / 255, (color & 255) / 255], dtype=np.float32)
        s = np.broadcast_to(s, base[..., :3].shape)
    else:
        s = np.where(la > 0, layer[..., :3] / np.maximum(la, 1e-9), 0)
    ba = base[..., 3:4]
    b = np.where(ba > 0, base[..., :3] / np.maximum(ba, 1e-9), 0)
    if mode == 'overlay':
        r = np.where(b < 0.5, 2 * b * s, 1 - 2 * (1 - b) * (1 - s))
    elif mode == 'hardlight':
        r = np.where(s < 0.5, 2 * b * s, 1 - 2 * (1 - b) * (1 - s))
    else:
        raise ValueError(mode)
    # where the base is empty Flash draws the layer's colour over nothing
    r = r * ba + s * (1 - ba)
    out_a = ba + la * (1 - ba)
    rgb = base[..., :3] * (1 - la) + r * la
    return np.concatenate([rgb, out_a], axis=-1)


def bounds_flash(sid, frame=1, keep=None, inst=None):
    """getBounds of a symbol instance in its own space, the way Flash computes it: every leaf's bounds rectangle
    transformed by its whole matrix (not nested boxes)"""
    if inst is None:
        inst = R.Instance(G, sid)
        inst.goto_and_stop(frame)
    xs, ys = [], []

    def rec(i, M):
        for d, e in i.display.items():
            if keep is not None and i is inst and not keep(d):
                continue
            m = R.mat_mul(M, e['matrix'])
            if e['inst'] is not None:
                rec(e['inst'], m)
                continue
            c = e['char']
            r = G.shapes.get(c) or TEXT_BOUNDS.get(c) or G.texts.get(c)
            if r is None:
                continue
            for (px, py) in ((r[0], r[2]), (r[1], r[2]), (r[0], r[3]), (r[1], r[3])):
                xs.append(m['a'] * px + m['c'] * py + m['tx'])
                ys.append(m['b'] * px + m['d'] * py + m['ty'])
    rec(inst, R.IDENT)
    return [min(xs), max(xs), min(ys), max(ys)]


def bake(name, premul_z4, box, res, white=False, mask=False, bounds=None, white_only=False):
    ox, oy = box[0], box[1]
    im = to_image(premul_z4, 4 // res if res <= 4 else 1)
    if res == 8:
        raise ValueError('bake at 8')
    mim = to_image(premul_z4, 1) if mask else None
    if white_only:
        im = white_of(im)
    return emit_leaf(name, im, ox, oy, res, white, mim, (ox, oy), bounds, bounds)


# synthetic symbols written by the bakes: sid -> frame lists (same format as frame_lists)
SYNTH = {}
synth_ids = iter(range(9001, 9999))


def leaf_entry(d, f, leaf, matrix=R.IDENT, name=None, variant=False):
    e = entry(d, f, ('leaf', leaf))
    e['matrix'] = matrix
    e['name'] = name
    e['variant'] = variant
    return e


def bake_tracks():
    """TankTracks (162): a tread scrolling under a mask, 6 frames (gotoAndStop by the code)"""
    snaps = [R.frame_states(G, 162, [f])[0] for f in range(1, 7)]
    cmds = [collect_depths(s, lambda d: True) for s in snaps]
    box = canvas_for(cmds)
    fl = []
    for f, (s, c) in enumerate(zip(snaps, cmds), 1):
        n = bake('B162_%d' % f, draw_z4(c, box), box, 2, mask=True, bounds=bounds_flash(162, f))
        fl.append([leaf_entry(1, 1, n)])
    SYNTH[162] = fl


def bake_glow():
    """sprite 165 (in col1 of the tank: 201 frames of a blurred bar, the code colours col1): white pictures"""
    sid = 165
    snaps = R.timeline(G, sid)
    cmds = [collect_depths(s, lambda d: True) for s in snaps]
    box = canvas_for(cmds, margin=1)
    fl = []
    for f, c in enumerate(cmds, 1):
        n = bake('B165_%d' % f, draw_z4(c, box), box, 2, mask=True, bounds=bounds_flash(sid, f), white_only=True)
        fl.append([leaf_entry(1, 1, n)])
    SYNTH[sid] = fl


def bake_tank():
    """Tank (181): col2 (sprite 170, 'overlay', coloured by the code) over the body: the body's top shape (168)
    and col2 as one picture per colour, drawn at the depth of 168; col2 stays as an empty named clip"""
    inst = R.Instance(G, 181)
    inst.goto_and_stop(1)
    base_c = collect_depths(inst, lambda d: 5 <= d <= 16)
    top_c = collect_depths(inst, lambda d: d == 16)
    col_c = collect_depths(inst, lambda d: d == 17)
    box = canvas_for([top_c, col_c])
    base = draw_z4(base_c, box)
    top = draw_z4(top_c, box)
    col = draw_z4(col_c, box)
    cover = np.maximum(top[..., 3:4], col[..., 3:4])
    b = bounds_flash(181, keep=lambda d: d in (16, 17))
    names = []
    for k, c in enumerate(PALETTE):
        res = blend_flash(base, col, 'overlay', c)
        # the picture: the result where 168 or col2 is drawn (opaque there), the base below it stays separate
        ra = res[..., 3:4]
        rgb = np.where(ra > 0, res[..., :3] / np.maximum(ra, 1e-9), 0)
        pic = np.concatenate([rgb * cover, cover], axis=-1)
        names.append(bake('B181_%d' % k, pic, box, 2, white=True, mask=True, bounds=b))
    return names


def bake_canon():
    """TankCanon (180): shape 177 + col3 (179, 'overlay', coloured by the code): one picture per colour"""
    inst = R.Instance(G, 180)
    base_c = collect_depths(inst, lambda d: d == 4)
    col_c = collect_depths(inst, lambda d: d == 5)
    box = canvas_for([base_c, col_c])
    base = draw_z4(base_c, box)
    col = draw_z4(col_c, box)
    b = bounds_flash(180)
    names = []
    for k, c in enumerate(PALETTE):
        names.append(bake('B180_%d' % k, blend_flash(base, col, 'overlay', c), box, 2, white=True, mask=True, bounds=b))
    SYNTH[180] = [[leaf_entry(4, 1, names[0], variant=True), entry(5, 1, None) | dict(name='col3', char=('empty',))]]
    leaves_variants['B180'] = names


def bake_shot():
    """Shot (158): 152 + the blinking core 155 (10 frames, playing) + col1 (157 'hardlight', coloured by the code):
    one picture per frame of the core and per colour. 158 becomes: a 10-frame clip of those pictures + col1 empty"""
    snaps = R.timeline(G, 158, 10)
    base_cs = [collect_depths(s, lambda d: d < 5) for s in snaps]
    col_cs = [collect_depths(s, lambda d: d == 5) for s in snaps]
    box = canvas_for(base_cs + col_cs)
    sub = []
    for f in range(10):
        base = draw_z4(base_cs[f], box)
        col = draw_z4(col_cs[f], box)
        b = bounds_flash(158, inst=snaps[f])
        names = []
        for k, c in enumerate(PALETTE):
            names.append(bake('B158_%d_%d' % (f + 1, k), blend_flash(base, col, 'hardlight', c), box, 2, bounds=b))
        leaves_variants['B158_%d' % (f + 1)] = names
        sub.append([leaf_entry(1, 1, names[0], variant=True)])
    core = next(synth_ids)
    SYNTH[core] = sub
    e = entry(1, 1, core)
    SYNTH[158] = [[e, dict(entry(5, 1, ('empty',)), name='col1')]]


def bake_optshotrate():
    """OptShotRate (205): three dots of fixed colours in 'hardlight': one picture"""
    inst = R.Instance(G, 205)
    ds = sorted(inst.display)
    box = canvas_for([collect_depths(inst, lambda d: True)])
    canvas = np.zeros((int((box[3] - box[1]) * 4), int((box[2] - box[0]) * 4), 4), dtype=np.float32)
    for d in ds:
        e = inst.display[d]
        layer = draw_z4(collect_depths(inst, lambda x, d=d: x == d), box)
        if e.get('blend') == 'hardlight':
            canvas = blend_flash(canvas, layer, 'hardlight')
        else:
            canvas = canvas * (1 - layer[..., 3:4]) + layer
    n = bake('B205', canvas, box, 2, mask=True, bounds=bounds_flash(205))
    SYNTH[205] = [[leaf_entry(1, 1, n)]]


leaves_variants = {}

# ---------------------------------------------------------------- the bitmaps of the ground (Texture1 / Texture2):
# copied by the game into repeating textures (GroundTex)
for n, f in (('TEX1', '225_Texture1.jpg'), ('TEX2', '226_Texture2.jpg')):
    im = Image.open(os.path.join(W, 'img_tank', f)).convert('RGBA')
    d = os.path.join(SRC, n)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, '0.png'))
    pivots[n] = [0, 0]

# ---------------------------------------------------------------- export
bake_tracks()
bake_glow()
tank_body = bake_tank()
leaves_variants['B181'] = tank_body
bake_canon()
bake_shot()
bake_optshotrate()

# the tank's frame list: 168 (d16) replaced by the baked body (variant), col2 (d17) empty
tank_fl = frame_lists(181)
for fl in tank_fl:
    for i, e in enumerate(fl):
        if e['depth'] == 16:
            fl[i] = dict(e, char=('leaf', tank_body[0]), variant=True, matrix=R.IDENT)
        elif e['depth'] == 17:
            fl[i] = dict(e, char=('empty',))
SYNTH[181] = tank_fl

symbols = {}
order = []


def need(sid, white, mask, scale):
    """exports a symbol (frame lists) and the leaves under it"""
    key = (sid, white, mask)
    fls = SYNTH.get(sid) or frame_lists(sid)
    if sid not in symbols:
        symbols[sid] = None
        order.append(sid)
    out = []
    for fl in fls:
        row = []
        for e in fl:
            c = e['char']
            m = e['matrix']
            s2 = scale * mscale(m)
            if isinstance(c, tuple):
                if c[0] == 'leaf':
                    ref = ('L', c[1])
                else:
                    ref = ('E', None)
            elif c in G.sprites or c in SYNTH:
                need(c, white, mask, s2)
                ref = ('M', c)
            elif c in G.texts:
                ref = ('F', c)
            elif c in G.shapes or c in TEXT_BOUNDS:
                ref = ('L', leaf_for_char(c, s2, white, mask))
            else:
                warn('unknown char %s in %d' % (c, sid))
                continue
            row.append((e, ref))
        out.append(row)
    symbols[sid] = out


for sid in ROOTS:
    need(sid, sid in WHITE_ROOTS or any(sid in reach_sprites for reach_sprites in ()), sid in MASK_ROOTS,
         CODE_SCALE.get(sid, 1.0))
# second pass with the flags of the roots that share symbols (white / mask from any root reaching a leaf)
for sid in WHITE_ROOTS + MASK_ROOTS:
    need(sid, sid in WHITE_ROOTS, sid in MASK_ROOTS, CODE_SCALE.get(sid, 1.0))
for sid in ROOTS:
    need(sid, sid in WHITE_ROOTS, sid in MASK_ROOTS, CODE_SCALE.get(sid, 1.0))

# ---------------------------------------------------------------- tables
CX = []
cx_index = {}
NAMES = []
name_index = {}
FX = []
fx_index = {}


def idx(table, index, v):
    k = json.dumps(v, sort_keys=True)
    if k not in index:
        index[k] = len(table)
        table.append(v)
    return index[k]


def r4(v):
    return round(v, 5)


sym_out = {}
for sid in order:
    frames = []
    uniq = {}
    fidx = []
    for row in symbols[sid]:
        ents = []
        for e, ref in row:
            m = e['matrix']
            cx = e['cx']
            ci = -1
            if cx != R.NOCX:
                ci = idx(CX, cx_index, [r4(x) for x in cx['mult']] + [int(x) for x in cx['add']])
            ni = -1
            if e.get('name'):
                ni = idx(NAMES, name_index, e['name'])
            fi = -1
            if e.get('filters') or e.get('blend') not in (None, 'normal'):
                fi = idx(FX, fx_index, dict(filters=e.get('filters') or [], blend=e.get('blend')))
            kind, r = ref
            ents.append([kind, r if r is not None else 0, e['key'], r4(m['a']), r4(m['b']), r4(m['c']), r4(m['d']),
                         r4(m['tx']), r4(m['ty']), ci, ni, e['clip'] or 0, fi, 1 if e.get('variant') else 0])
        k = json.dumps(ents)
        if k not in uniq:
            uniq[k] = len(frames)
            frames.append(ents)
        fidx.append(uniq[k])
    sym_out[sid] = dict(frames=frames, idx=fidx, cls=CLASSES.get(sid))

# ---------------------------------------------------------------- text fields: glyphs of their embedded fonts
from PIL import ImageDraw, ImageFont


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
        if not flags & 0x80:
            continue
        asc, desc, lead = struct.unpack_from('<HHh', body, q); q += 6
        adv = struct.unpack_from('<%dh' % ng, body, q)
        out[fid] = dict(codes=codes, ascent=asc / em, descent=desc / em, adv={chr(c): v / em for c, v in zip(codes, adv)})
    return out


FONTS = font_layouts(W + 'tank.swf')
TTF = {f.split('_', 1)[0]: os.path.join(W, 'fonts_tank', f) for f in os.listdir(W + 'fonts_tank')}
GLYPHS = '0123456789:'


def glyph_anim(cid, e, res=2):
    """the glyphs of a text field as images whose pivot is the pen position on the baseline"""
    lay = FONTS[e['font']]
    size = e['height']
    SS = 4
    font = ImageFont.truetype(TTF[str(e['font'])], int(round(size * res * SS)))
    chars = [c for c in GLYPHS if c in lay['adv']]
    pad = 3
    w = int(math.ceil(max(lay['adv'][c] for c in chars) * size * res)) + 2 * pad + 4
    h = int(math.ceil((lay['ascent'] + lay['descent']) * size * res)) + 2 * pad + 2
    ox, oy = pad + 1, pad + int(math.ceil(lay['ascent'] * size * res))
    name = 'G%d' % cid
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    rgb = tuple(int(e['color'][i:i + 2], 16) for i in (1, 3, 5))
    for i, ch in enumerate(chars):
        big = Image.new('L', (w * SS, h * SS), 0)
        ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.BOX)
        g = Image.new('RGBA', (w, h), rgb + (0,))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)))
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    return dict(chars=''.join(chars), adv=[round(lay['adv'][c] * size, 4) for c in chars],
                ascent=round(lay['ascent'] * size, 4), res=res)


edits = {}
for cid, e in EDITS.items():
    edits[cid] = dict(b=e['bounds'], font=e['fontInfo']['name'], size=e['height'], color=e['color'],
                      align=e.get('align', 'left'), leading=e.get('leading', 0))
    if cid in (100, 104):
        edits[cid]['glyphs'] = glyph_anim(cid, e)

data = dict(symbols=sym_out, leaves=leaves, masks=MASKS, variants=leaves_variants, cx=CX, names=NAMES, fx=FX, palette=PALETTE,
            edits=edits)
json.dump(data, open(os.path.join(OUT, 'data.json'), 'w'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)

area = {}
for n in pivots:
    if n.startswith('G') or n.startswith('TEX'):
        continue
    im = Image.open(os.path.join(SRC, n, '0.png'))
    bb = im.getbbox()
    area[n] = (bb[2] - bb[0]) * (bb[3] - bb[1]) if bb else 0
tot = sum(area.values())
print('symbols %d, leaves %d, pictures %d, area %d px (%.0f%% of a 2040 sheet)' % (
    len(sym_out), len(leaves), len(pivots), tot, 100 * tot / 2040 / 2040))
for n, a in sorted(area.items(), key=lambda t: -t[1])[:15]:
    print('  %8d %s' % (a, n))
print('warnings', len(WARN))
