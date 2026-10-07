"""Phagocytoz (archive folder Fragocytoz): gfx.swf (the graphics library linked into game.swf, AS3) -> leaf pictures +
timeline tables, in the format of Happy Pti Tank (happyptitank_assets.py): the game keeps the AS3 display list of the
original (Display.hx / MovieClip.hx) and PIXI only draws it.

What is particular here:
  - the cells (McCell: env + noyau) are 100 x 100 symbols scaled by the code from a few pixels to more than the
    screen (ray up to 150+, zoom of the level up to 6): their shapes get pictures at several resolutions (lods),
    the game picks the one that fits the size it draws them at;
  - the worm of McMicroCell (sprite 27, vers_12) is made of morph shapes: its frames are FFDec renders;
  - the background is a BitmapData drawn once by Game.initBg (McBg 3 x 3 over a 0x1C1D42 rectangle, drawn x2 into a
    1200 x 1200 bitmap shown at 1/2): baked here at the bitmap's own resolution (BG), drawn unsmoothed like Flash's
    Bitmap (smoothing false);
  - the title's black square (shape 32) is a solid rectangle (no picture);
  - the text fields: the score (Arial Black, digits, scaled up to x9 by the code: glyphs at several resolutions) and
    the phase ("phase #N", Wolven Script).

usage: phagocytoz_assets.py <out dir>   (after prepare_game.sh + the exports of rebuild_assets.sh)
Writes <out>/src/<leaf>/0.png, <out>/pivots.json, <out>/data.json.
"""
import os, sys, json, math, re, zlib, struct
import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfrender as R
import swftext
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'phagocytoz', '')
OUT = sys.argv[1] if len(sys.argv) > 1 else W + 'out'
SRC = os.path.join(OUT, 'src')

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
G.flash_replace = True
RD = R.Renderer(G, 2)

# classes bound to the symbols (SymbolClass tag of gfx.swf)
CLASSES = {53: 'McBg', 48: 'McCell', 47: 'noyau_4', 38: 'FxStar', 35: 'McTitle', 31: 'McPhase', 28: 'McMicroCell',
           27: 'vers_12', 17: 'McBurst', 15: 'McScore', 14: 'GfxScore', 11: 'McArrow', 9: 'big', 6: 'McBlock',
           2: 'BlueSquare'}
# the symbols the game creates (McBg is baked into BG; FxStar, McBurst, McBlock, big, BlueSquare are never used)
ROOTS = [48, 28, 35, 11, 15]

# frame scripts of the bound classes (as_gfx: addFrameScript in their constructors). 's' stop, ['r', lo, hi]
# gotoAndPlay(lo + random(hi - lo + 1)) (visual), ['g', f] gotoAndPlay(f)
SCRIPTS = {
    48: {1: ['s']},                 # McCell
    47: {1: ['s']},                 # noyau_4
    35: {22: ['s']},                # McTitle (Game adds endTitle on frame 37)
    15: {42: ['s']},                # McScore
    28: {1: ['s']},                 # McMicroCell
    27: {1: [['r', 1, 50]], 53: [['g', 2]]},   # vers_12: gotoAndPlay(floor(random * 50 + 1)); frame 53: gotoAndPlay(2)
}

# resolutions (pixels per Flash unit) of the pictures of a shape: the code scales them (see the header)
#   env (39 / 40 / 41: 100 units wide): a cell of ray r is drawn 2 r * zoom * 2 canvas pixels wide
#   noyau (43 / 45 / 46: 20 units): up to 2 x the cell's scale
LODS = {39: [0.5, 1, 2, 4, 8], 40: [0.5, 1, 2, 4, 8], 41: [0.5, 1, 2, 4, 8],
        43: [1, 2, 4, 8, 16], 45: [1, 2, 4, 8, 16], 46: [1, 2, 4, 8, 16]}
LOD_SRC = {39: ('shp8_gfx', 8), 40: ('shp8_gfx', 8), 41: ('shp8_gfx', 8),
           43: ('shp16_gfx', 16), 45: ('shp16_gfx', 16), 46: ('shp16_gfx', 16)}
# shapes drawn as a solid rectangle (no picture): the title's black square
SOLID = {32: 0x000000}
# the worm (sprite 27) is shown at x1.84 in McMicroCell: its frames at 4 px per unit
WORM = 27
WORM_DIR = W + 'spr4_gfx/DefineSprite_27_gfx_fla.vers_12'
# the score's text field (edit 13) is scaled up to ~x9 on the stage by the code: glyphs at several resolutions
GLYPH_RES = {13: [2, 4, 8, 16], 30: [2]}
GLYPH_CHARS = {13: '0123456789', 30: 'phase #0123456789'}

os.makedirs(SRC, exist_ok=True)
pivots = {}
leaves = {}
WARN = []


def warn(s):
    WARN.append(s)
    print('WARN', s)


# ---------------------------------------------------------------- the worm: FFDec renders of its frames
def inject_ffdec_sprite(sid, folder):
    """each frame of the sprite becomes one pseudo shape (FFDec draws every frame on one canvas whose origin is the
    top left corner of the union of the sprite's shape rectangles, see magmax_swf.py)"""
    sd = G.sprites[sid]
    chars = {v['char'] for ops in sd.frames for k, v in ops if k == 'place' and 'char' in v}
    rects = [G.shapes[c] for c in chars]
    ox, oy = min(r[0] for r in rects), min(r[2] for r in rects)
    frames = []
    pseudo = {}
    for f in range(1, sd.nframes + 1):
        im = Image.open(os.path.join(folder, '%d.png' % f)).convert('RGBA')
        if im.getbbox() is None:
            frames.append([('remove', 1)])
            continue
        pid = 100000 + sid * 100 + f
        G.shapes[pid] = [ox, ox + im.width / G.Z, oy, oy + im.height / G.Z]
        G._shape_cache[pid] = im
        pseudo[pid] = im
        frames.append([('place', dict(depth=1, char=pid, matrix=R.IDENT, move=f > 1))])
    sd.frames = frames
    return pseudo


WORM_FRAMES = inject_ffdec_sprite(WORM, WORM_DIR)


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


# ---------------------------------------------------------------- pictures
def save_png(name, im, ox, oy, res):
    """a picture: im covers Flash units from (ox, oy) at res pixels per unit (pivot: the origin of the shape)"""
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, '0.png'))
    pivots[name] = [round(-ox * res / im.width, 6), round(-oy * res / im.height, 6)]


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
    im = pad_to(im, k)
    a = np.asarray(im.convert('RGBA'), dtype=np.float64) / 255.0
    a[..., :3] *= a[..., 3:4]
    h, w = a.shape[0] // k, a.shape[1] // k
    a = a[:h * k, :w * k].reshape(h, k, w, k, 4).mean(axis=(1, 3))
    rgb = np.where(a[..., 3:4] > 0, a[..., :3] / np.maximum(a[..., 3:4], 1e-9), 0)
    out = np.concatenate([rgb, a[..., 3:4]], axis=-1)
    return Image.fromarray(np.clip(out * 255 + 0.5, 0, 255).astype(np.uint8), 'RGBA')


def shape_png(cid, folder):
    return Image.open(os.path.join(W, folder, '%d.png' % cid)).convert('RGBA')


# the membranes (39 / 40 / 41) have an outline 0.1 unit wide: Flash draws a stroke thinner than a pixel one pixel
# wide, whatever the scale (1 stage pixel: 2 canvas pixels, the cells being drawn from a few pixels to more than the
# screen). Their pictures are drawn without it (the FFDec SVG minus that path, by rsvg-convert) and the game draws it
# at run time (Leaf: hair)
HAIR = (39, 40, 41)


def parse_path(d):
    """SVG path of FFDec (M / L / Q, absolute, implicit repeats) -> [["M", x, y], ["Q", cx, cy, x, y], ["L", x, y]]"""
    toks = re.findall(r'[MLQZ]|-?[0-9.]+(?:e-?[0-9]+)?', d)
    out, cmd, i = [], None, 0
    while i < len(toks):
        t = toks[i]
        if t in 'MLQZ':
            cmd = t
            i += 1
            if t == 'Z':
                out.append(['Z'])
            continue
        n = 4 if cmd == 'Q' else 2
        out.append([cmd] + [round(float(v), 3) for v in toks[i:i + n]])
        i += n
        if cmd == 'M':
            cmd = 'L'
    return out


def hair_split(cid, zoom):
    """the shape at `zoom` without its hairline path, and that path (ops, colour, alpha)"""
    import subprocess, io
    svg = open(os.path.join(W, 'svg_gfx', '%d.svg' % cid)).read()
    m = re.search(r'\s*<path d="([^"]*)" ffdec:has-small-stroke="true"[^>]*stroke="(#[0-9a-f]{6})"[^>]*'
                  r'stroke-opacity="([0-9.]+)"[^>]*/>', svg)
    if m is None:
        raise ValueError('no hairline in %d' % cid)
    hair = dict(path=parse_path(m.group(1)), color=int(m.group(2)[1:], 16), alpha=round(float(m.group(3)), 4))
    rest = svg[:m.start()] + svg[m.end():]
    r = subprocess.run(['rsvg-convert', '-z', str(zoom)], input=rest.encode(), capture_output=True, check=True)
    return Image.open(io.BytesIO(r.stdout)).convert('RGBA'), hair


def leaf_for_char(c):
    name = 'S%d' % c
    if name in leaves:
        return name
    x0, x1, y0, y1 = G.shapes[c]
    L = dict(b=[round(v, 3) for v in (x0, x1, y0, y1)], ox=x0, oy=y0)
    if c in SOLID:
        L.update(solid=SOLID[c], res=1, w=x1 - x0, h=y1 - y0)
    elif c in LODS:
        folder, z = LOD_SRC[c]
        if c in HAIR:
            # (rendered at 2 x the top resolution, reduced: the same anti-aliasing as the FFDec renders)
            top, hair = hair_split(c, 2 * z)
            top = reduce_premult(top, 2)
            L['hair'] = hair
        else:
            top = shape_png(c, folder)
        lods = []
        for i, res in enumerate(LODS[c]):
            if res < 1:
                im = reduce_premult(top, int(z / res))
            else:
                im = reduce_premult(top, int(z // res))
            n = '%s_%d' % (name, i)
            save_png(n, im, x0, y0, res)
            lods.append([res, n])
        L.update(lods=lods, res=LODS[c][-1], w=x1 - x0, h=y1 - y0)
    elif c in WORM_FRAMES:
        im = WORM_FRAMES[c]
        save_png(name, im, x0, y0, 4)
        L.update(res=4, w=im.width / 4, h=im.height / 4)
    else:
        im = reduce_premult(shape_png(c, 'shp4_gfx'), 2)
        save_png(name, im, x0, y0, 2)
        L.update(res=2, w=im.width / 2, h=im.height / 2)
    leaves[name] = L
    return name


# ---------------------------------------------------------------- symbols
symbols = {}
order = []


def need(sid):
    if sid in symbols:
        return
    symbols[sid] = None
    order.append(sid)
    out = []
    for fl in frame_lists(sid):
        row = []
        for e in fl:
            c = e['char']
            if c in G.sprites:
                need(c)
                ref = ('M', c)
            elif c in G.texts:
                ref = ('F', c)
            elif c in G.shapes:
                ref = ('L', leaf_for_char(c))
            else:
                warn('unknown char %s in %d' % (c, sid))
                continue
            row.append((e, ref))
        out.append(row)
    symbols[sid] = out


for sid in ROOTS:
    need(sid)

CX, cx_index, NAMES, name_index, FX, fx_index = [], {}, [], {}, [], {}


def idx(table, index, v):
    k = json.dumps(v, sort_keys=True)
    if k not in index:
        index[k] = len(table)
        table.append(v)
    return index[k]


def r5(v):
    return round(v, 5)


sym_out = {}
for sid in order:
    frames, uniq, fidx = [], {}, []
    for row in symbols[sid]:
        ents = []
        for e, ref in row:
            m = e['matrix']
            cx = e['cx']
            ci = -1
            if cx != R.NOCX:
                # (alpha multipliers: 8.8 fixed point, like the ColorTransform of the SWF)
                ci = idx(CX, cx_index, [r5(x) for x in cx['mult']] + [int(x) for x in cx['add']])
            ni = idx(NAMES, name_index, e['name']) if e.get('name') else -1
            fi = -1
            if e.get('filters') or e.get('blend') not in (None, 'normal'):
                # the title (35): the phase blurred and added, the disc added; the phase's field (31): two glows.
                # Drawn at run time (FlashFilter.hx); a glow of strength 0 draws nothing
                fl = [dict({k: (list(v) if isinstance(v, tuple) else v) for k, v in f.items()},
                           blurX=round(f.get('blurX', 0), 3), blurY=round(f.get('blurY', 0), 3))
                      for f in e.get('filters') or [] if not (f['type'] == 'glow' and f.get('strength') == 0)]
                fi = idx(FX, fx_index, dict(filters=fl, blend=e.get('blend')))
            kind, r = ref
            ents.append([kind, r, e['key'], r5(m['a']), r5(m['b']), r5(m['c']), r5(m['d']), r5(m['tx']), r5(m['ty']),
                         ci, ni, e['clip'] or 0, fi])
        k = json.dumps(ents)
        if k not in uniq:
            uniq[k] = len(frames)
            frames.append(ents)
        fidx.append(uniq[k])
    sc = SCRIPTS.get(sid, {})
    sym_out[sid] = dict(frames=frames, idx=fidx, cls=CLASSES.get(sid), scripts={str(f): v for f, v in sc.items()})


# ---------------------------------------------------------------- background: the BitmapData of Game.initBg
def bake_bg():
    """brush: a 600 x 600 rectangle 0x1C1D42 and McBg (frame 1, stop) at (1 - x) * 300, (1 - y) * 300; drawn with a
    matrix scale 2 into a 1200 x 1200 bitmap (filled 0x1C1D42, opaque): 2 pixels per unit, like the textures"""
    inst = R.Instance(G, 53)
    inst.goto_and_stop(1)
    cmds = []
    for x in range(3):
        for y in range(3):
            M = dict(R.IDENT, tx=(1 - x) * 300.0, ty=(1 - y) * 300.0)
            RD.collect(inst, M, R.NOCX, set(), cmds)
    Z = G.Z
    canvas = np.zeros((600 * Z, 600 * Z, 4), dtype=np.float32)
    RD.draw(cmds, canvas, (0, 0))
    bgc = np.array([0x1C / 255, 0x1D / 255, 0x42 / 255, 1.0], dtype=np.float32)
    canvas = canvas + bgc * (1 - canvas[..., 3:4])
    k = Z // 2
    a = canvas.reshape(1200, k, 1200, k, 4).mean(axis=(1, 3))
    im = Image.fromarray(np.clip(a[..., :3] * 255 + 0.5, 0, 255).astype(np.uint8), 'RGB').convert('RGBA')
    save_png('BG', im, 0, 0, 2)


bake_bg()


# ---------------------------------------------------------------- text fields: glyphs of their embedded fonts
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


FONTS = font_layouts(W + 'gfx.swf')
TTF = {f.split('_', 1)[0]: os.path.join(W, 'fonts_gfx', f) for f in os.listdir(W + 'fonts_gfx')}
EDITS = swftext.all_edittexts(W + 'gfx.swf')


def glyph_anim(cid, e, res):
    """the glyphs of a text field as images whose pivot is the pen position on the baseline"""
    lay = FONTS[e['font']]
    size = e['height']
    SS = 4
    font = ImageFont.truetype(TTF[str(e['font'])], int(round(size * res * SS)))
    chars = [c for c in GLYPH_CHARS[cid] if c in lay['adv']]
    missing = [c for c in GLYPH_CHARS[cid] if c not in lay['adv']]
    if missing:
        warn('edit %d: no glyph for %r' % (cid, ''.join(missing)))
    pad = 3
    # one canvas for every glyph: the union of their boxes around the pen position (script fonts draw far left of
    # the pen and past the advance)
    boxes = [font.getbbox(c, anchor='ls') for c in chars if c != ' ']
    bx0 = min(b[0] for b in boxes) / SS
    by0 = min(b[1] for b in boxes) / SS
    bx1 = max(b[2] for b in boxes) / SS
    by1 = max(b[3] for b in boxes) / SS
    ox = pad + int(math.ceil(-bx0))
    oy = pad + int(math.ceil(-by0))
    w = ox + int(math.ceil(bx1)) + pad
    h = oy + int(math.ceil(by1)) + pad
    name = 'G%d_%d' % (cid, res)
    d = os.path.join(SRC, name)
    os.makedirs(d, exist_ok=True)
    rgb = tuple(int(e['color'][i:i + 2], 16) for i in (1, 3, 5))
    for i, ch in enumerate(chars):
        big = Image.new('L', (w * SS, h * SS), 0)
        if ch != ' ':
            ImageDraw.Draw(big).text((ox * SS, oy * SS), ch, font=font, fill=255, anchor='ls')
        al = big.resize((w, h), Image.BOX)
        if al.getbbox() is not None and (al.getbbox()[0] == 0 or al.getbbox()[2] == w or al.getbbox()[3] == h):
            warn('glyph %r of %s touches its border' % (ch, name))
        g = Image.new('RGBA', (w, h), rgb + (0,))
        g.putalpha(al)
        g.save(os.path.join(d, '%d.png' % (i + 1)))
    pivots[name] = [round(ox / w, 6), round(oy / h, 6)]
    return chars, lay


edits = {}
for cid in GLYPH_RES:
    e = EDITS[cid]
    ls = re.search(r'letterSpacing="([-0-9.]+)"', e.get('text', ''))
    E = dict(b=e['bounds'], font=e['fontInfo']['name'], size=e['height'], color=e['color'], align=e.get('align', 'left'),
             leading=e.get('leading', 0), letterSpacing=float(ls.group(1)) if ls else 0.0, glyphs=[])
    for res in GLYPH_RES[cid]:
        chars, lay = glyph_anim(cid, e, res)
        E['glyphs'].append(dict(res=res, anim='G%d_%d' % (cid, res)))
    E['chars'] = ''.join(chars)
    E['adv'] = [round(lay['adv'][c] * e['height'], 4) for c in chars]
    E['ascent'] = round(lay['ascent'] * e['height'], 4)
    edits[cid] = E

data = dict(symbols=sym_out, leaves=leaves, cx=CX, names=NAMES, fx=FX, edits=edits)
json.dump(data, open(os.path.join(OUT, 'data.json'), 'w'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)

area = {}
for n in pivots:
    if n.startswith('G'):
        continue
    im = Image.open(os.path.join(SRC, n, '0.png'))
    bb = im.getbbox()
    area[n] = (bb[2] - bb[0]) * (bb[3] - bb[1]) if bb else 0
tot = sum(area.values())
print('symbols %d, leaves %d, pictures %d, area %d px (%.0f%% of a 2040 sheet)' % (
    len(sym_out), len(leaves), len(pivots), tot, 100 * tot / 2040 / 2040))
for n, a in sorted(area.items(), key=lambda t: -t[1])[:12]:
    print('  %8d %s' % (a, n))
print('warnings', len(WARN))
