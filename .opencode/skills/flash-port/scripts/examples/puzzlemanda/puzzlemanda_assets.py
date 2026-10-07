"""Builds the Puzzle-Manda graphics for KadoKadeo from the original SWF (archive folder PuzzleSnake: gfx.swf, the
graphics library the released game.swf was compiled with, same shapes and timelines, readable instance names).

Every symbol the game attaches is exported as a Clip (timeline tables played by puzzlemanda.Clip, see clipexport.py):
  - `bg` (its time bar `bar`, sprite 57, whitened in a loop when the time runs out), `back` (the frame of the grid,
    scaled by the code) and `title` (without its text field: the game draws "NIVEAU n" in the device font Impact);
  - `cell`: a fruit of the grid or of the sequence (`symbol`, sprite 44: frames 1..5 the fruits, 6..8 the bonuses,
    sprite 43 with three stars turning at random, recoloured by a ColorMatrixFilter on frames 7 and 8, applied at run
    time), its blink (frames 10..24: sprite 45, a copy `mc` of the symbol blurred by 10 px drawn in "add"), its
    appearance (30..40) and the body of the snake (60..65);
  - `snakeHead` (`ec` counter-rotated by the code), `suiteSnake` (its white glow baked), the particles `partOnde`,
    `partFruit` (Filt.glow(mc, 3, 1, 0) of the code baked: one black glow, invisible in "add" on the bonus frames) and
    `partDifuse` (white: Col.setPercentColor(mc, 100, colour) of the code is a tint).
The cells are Flash buttons: the mouse is tested on their shapes (run-length masks of the fruits, of the bonus' disc
and stars, of the snake's body).
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: puzzlemanda_assets.py <out dir>      (after prepare_game.sh: $KKP_WORK/puzzlemanda holds gfx.swf and its exports)
"""
import os, sys, json, shutil, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
from PIL import Image, ImageFont, ImageDraw
from fontTools.ttLib import TTFont
import swfrender as R
import clipexport as C
import swftext

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'puzzlemanda', '')
OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

G = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)
Gb = R.SWF(W + 'gfx.swf', W + 'shp4_gfx', Z=4)     # untouched timelines, for the measures
for X in (G, Gb):
    X.flash_replace = True
G.blur_filters = True
K = C.K


def clone(sid, nid, patch):
    """a copy of sprite sid whose placements go through patch(frame, placement) (None: dropped)"""
    sd = G.sprites[sid]
    nd = R.SpriteDef(nid, sd.nframes)
    nd.labels = dict(sd.labels)
    nd.actions = dict(sd.actions)
    for f, ops in enumerate(sd.frames, 1):
        out = []
        for k, v in ops:
            if k == 'place':
                v = patch(f, dict(v))
                if v is None:
                    continue
            out.append((k, v))
        nd.frames.append(out)
    G.sprites[nid] = nd
    return nid


# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM = {
    (42, 1): [['x', 'starRot']],     # star of a bonus: _rotation += 10 + Math.random() * 26
    (45, 1): [['x', 'mcSym']],       # blink of a cell: mc.gotoAndStop(_parent.symbol._currentframe)
    (3, 5): [['x', 'rmSelf']],       # partOnde: removeMovieClip("")
}

E = C.Exporter(G, SRC, '', CUSTOM)
E.effects = True
E.blurs = True
E.color_matrix = True
E.code_for = {45: ('mc',)}

E.export(59, 'bg', code=('bar',))
E.export(34, 'back')
# title without its text field (depth 2, "NIVEAU n" in a device font: drawn by the game)
TITLE = clone(20, 100020, lambda f, v: None if v.get('depth') == 2 else v)
E.export(TITLE, 'title')
# the frames the code shows: 1 (still), 10..24 (blink of the sequence), 30..40 (appearance), 60..65 (snake body)
CELL_FRAMES = [1] + list(range(10, 25)) + list(range(30, 41)) + list(range(60, 66))
E.export(52, 'cell', code=('symbol',), frames=CELL_FRAMES)
E.export(30, 'snakeHead', code=('ec',))
E.export(23, 'suiteSnake', strategy='flat')
E.export(3, 'partOnde')
# partFruit with the glow the code gives it (Filt.glow(p.root, 3, 1, 0): GlowFilter black, blur 3, strength 1,
# quality 1; the clip has one child: the glow of the clip is the glow of its child)
GLOW_FRUIT = dict(type='glow', color=(0, 0, 0, 255), blurX=3.0, blurY=3.0, strength=1.0, inner=False, knockout=False,
                  passes=1)
PART_FRUIT = clone(12, 100012, lambda f, v: dict(v, filters=list(v.get('filters') or []) + [GLOW_FRUIT]))
E.export(PART_FRUIT, 'partFruit', strategy='flat', frames=list(range(1, 9)))
E.export(14, 'partDifuse', cx=C.WHITE)

clips, pivots, area = E.clips, E.pivots, E.area
meta = {}


# ---------------------------------------------------------------- the buttons of the cells: their shapes (hit test)
# Flash tests the mouse on the shapes of a button clip (the cell: its symbol, or the body of the snake). The masks are
# in the coordinates of the clip that draws them, the game applies the matrices (meta below)
HZ = 4


def cmds_of(sid, frame=1, ctrl=None, X=None):
    X = X or G
    c = dict(ctrl or {})
    c['__noactions__'] = True
    c[sid] = frame
    inst = R.Instance(X, sid, ctrl=c)
    out = []
    R.Renderer(X, K).collect(inst, R.IDENT, R.NOCX, set(), out)
    return out


def rle(cmds):
    imgs, reg = E.render([cmds], HZ, margin=1)
    A = np.asarray(imgs[0], dtype=np.uint8)[..., 3] >= 128
    rows = []
    for y in range(A.shape[0]):
        r = A[y]
        runs = []
        x = 0
        while x < len(r):
            if r[x]:
                x0 = x
                while x < len(r) and r[x]:
                    x += 1
                runs.append([x0, x])
            else:
                x += 1
        rows.append(runs)
    return dict(ox=-reg[0] / HZ, oy=-reg[1] / HZ, rows=rows)


def matrix(sid, frame, pick):
    """[a, b, c, d, tx, ty] of the placement pick(depth, entry) of sprite sid on a frame"""
    inst = R.Instance(Gb, sid, ctrl={'__noactions__': True, sid: frame})
    es = [e for d, e in sorted(inst.display.items()) if pick(d, e)]
    assert len(es) == 1, (sid, frame, es)
    m = es[0]['matrix']
    return [round(m[k], 6) for k in ('a', 'b', 'c', 'd', 'tx', 'ty')]


# symbol frames 1..5 (the fruits, sprite 44 coordinates)
meta['hitSym'] = [rle(cmds_of(44, f)) for f in range(1, 6)]
# a bonus (frames 6..8 of the symbol): sprite 43 in the symbol, its disc (depth 1) and its three stars (sprite 42 at
# depths 2, 5, 8, turned by their frame script: the game gives their rotation)
assert all(matrix(44, f, lambda d, e: d == 1) == matrix(44, 6, lambda d, e: d == 1) for f in (7, 8))
meta['bonusMat'] = matrix(44, 6, lambda d, e: d == 1)
DISC = clone(43, 100043, lambda f, v: v if v.get('depth') == 1 else None)
meta['hitDisc'] = rle(cmds_of(DISC))
meta['hitStar'] = rle(cmds_of(42))
meta['starMats'] = [matrix(43, 1, lambda d, e, dd=dd: d == dd) for dd in (2, 5, 8)]
# the symbol in the cell on each frame it is there (null: absent)
symMat = []
for f in range(1, 66):
    inst = R.Instance(Gb, 52, ctrl={'__noactions__': True, 52: f})
    es = [e for e in inst.display.values() if e['name'] == 'symbol']
    symMat.append(None if not es else [round(es[0]['matrix'][k], 6) for k in ('a', 'b', 'c', 'd', 'tx', 'ty')])
meta['symMat'] = symMat
# the body of the snake (cell frames 60..65)
meta['hitBody'] = [rle(cmds_of(52, f)) for f in range(60, 66)]
# bg: the whole stage (the button behind the cells)
bgimg, bgreg = E.render([cmds_of(59)], 1, margin=0)
ba = np.asarray(bgimg[0])[..., 3]
print('bg', bgimg[0].size, bgreg, 'opaque', (ba == 255).mean())
meta['hitZ'] = HZ


# ---------------------------------------------------------------- title: "NIVEAU n" in the device font Impact
# title.field (edittext 19): font "impact" without glyphs (a device font: Flash drew it with the font of the player's
# computer), 12 px, white, left aligned, 2 px gutter, first baseline at top + 2 + ascent. Glyphs drawn from the TTF.
IMPACT = '/System/Library/Fonts/Supplemental/Impact.ttf'
TX = swftext.all_edittexts(W + 'gfx.swf')
t19 = TX[19]
assert t19['fontInfo']['name'] == 'impact' and t19['align'] == 'left' and not t19['html'], t19
CHARS = 'NIVEAU 0123456789'
fnt = TTFont(IMPACT)
em = float(fnt['head'].unitsPerEm)
cmap = fnt.getBestCmap()
lay = dict(ascent=fnt['hhea'].ascent / em, descent=-fnt['hhea'].descent / em,
           adv={c: fnt['hmtx'][cmap[ord(c)]][0] / em for c in CHARS})
size = t19['height']
SS = 4
font = ImageFont.truetype(IMPACT, int(round(size * K * SS)))
pad = 4
gw = int(math.ceil(max(lay['adv'][c] for c in CHARS) * size * K)) + 2 * pad + 8
gh = int(math.ceil((lay['ascent'] + lay['descent']) * size * K)) + 2 * pad + 2
gox, goy = pad + 3, pad + int(math.ceil(lay['ascent'] * size * K))
d = os.path.join(SRC, 'glyph')
os.makedirs(d, exist_ok=True)
for i, ch in enumerate(CHARS):
    big = Image.new('L', (gw * SS, gh * SS), 0)
    ImageDraw.Draw(big).text((gox * SS, goy * SS), ch, font=font, fill=255, anchor='ls')
    al = big.resize((gw, gh), Image.LANCZOS)
    g = Image.new('RGBA', (gw, gh), (255, 255, 255, 0))
    g.putalpha(al)
    g.save(os.path.join(d, '%d.png' % (i + 1)), optimize=True)
pivots['glyph'] = [round(gox / gw, 6), round(goy / gh, 6)]
area['glyph'] = gw * gh * len(CHARS)
inst = R.Instance(Gb, 20, ctrl={'__noactions__': True})
fe = [e for e in inst.display.values() if e['name'] == 'field'][0]
fm = fe['matrix']
assert abs(fm['a'] - 1) < 3e-3 and abs(fm['d'] - 1) < 3e-3 and fm['b'] == 0 and fm['c'] == 0, fm
meta['titleField'] = dict(x=round(fm['tx'] + t19['bounds'][0] + 2, 3),
                          base=round(fm['ty'] + t19['bounds'][2] + 2 + lay['ascent'] * size, 3),
                          chars=CHARS, adv=[round(lay['adv'][c] * size, 4) for c in CHARS],
                          color=int(t19['color'][1:], 16))
print('titleField', meta['titleField'])

for nm, cd in clips.items():
    print('%-12s n=%-3d r=%.2f %s' % (nm, cd['n'], cd['r'], [(L['k'], L['a'], L.get('nm'), L.get('bl'), 'cms' in L, 'bf' in L, 'fl' in L, L.get('tn'), 'tns' in L, L.get('ad'), 'ads' in L) for L in cd['layers']]))
    if 'acts' in cd:
        print('   acts', cd['acts'])
print('matrices', meta['bonusMat'], meta['starMats'])
print('symMat', [(i + 1, m) for i, m in enumerate(symMat) if m])
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
