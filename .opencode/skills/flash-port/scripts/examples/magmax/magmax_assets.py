"""Builds the Magmax graphics for KadoKadeo from the original SWF (gfx.swf, the graphics of the released gaunt.swf).

Every symbol the game attaches is exported as a Clip (timeline tables played by magmax.Clip, see clipexport.py):
  - the hero (60 directions), the 3 monsters (their `sub` clip: 60 / 60 / 43 frames chosen by the code) and the
    death are flattened per frame; the nested animations that keep playing on their own (bubbling lava, propeller,
    flames...) stay separate clips;
  - the two sprites drawn with morph shapes (the lava blob inside the hero and monster 3, the fireball of monster
    1) are FFDec renders of the sprite, frame by frame (swfrender does not draw morph shapes);
  - the static texts of the combo messages (DefineText, Impact font embedded in the SWF) are drawn from the font
    exported by FFDec with the glyph positions of the SWF;
  - the red hero shot and the red shot sparks (Hero.setColor(mc, 0xFF0000) during the speed bonus) are baked
    variants; the bonus gems are one variant per colour (colour transforms no tint can do);
  - the background is the 300 x 300 bitmap of the SWF at its native resolution (drawn x2).
The gameplay hitTests read bounds: they are measured here on the SWF shapes (Flash bounds: every shape rectangle
through its full matrix) and written in meta.json.
Writes <out>/src (images), <out>/pivots.json, <out>/clips.json and <out>/meta.json.
usage: magmax_assets.py <out dir>
"""
import os, sys, json, shutil, math
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import numpy as np
import swfrender as R
import clipexport as C

OUT = sys.argv[1]
SRC = os.path.join(OUT, 'src')
if os.path.isdir(SRC):
    shutil.rmtree(SRC)
os.makedirs(SRC)

from magmax_swf import W, G, Gp, Gb

# ---------------------------------------------------------------- clips
# frame scripts that are not plain playhead moves (decompiled in as_gfx/)
CUSTOM_G = {
    (13, 19): [['x', 'rmSelf']],        # blam: removeMovieClip(this)
    (239, 15): [['x', 'rmSelf']],       # boum
    (62, 29): [['x', 'rmSelf']],        # death (Game.main waits for death._name == null)
    (107, 11): [['x', 'rmParent']],     # spark of a shot (plop.sub): _parent.removeMovieClip()
    (36, 9): [['x', 'compt']],          # comment: compt = 30
    (36, 11): [['x', 'comptLoop']],     # comment: if (compt-- > 0) gotoAndPlay(_currentframe - 1)
    (36, 22): [['x', 'rmSelf']],        # comment: removeMovieClip("")
    (23, 1): [['r', 1, 39]],            # option particle: gotoAndPlay(random(39) + 1)
    (24, 1): [['x', 'dup6']],           # option: 6 copies of "a" turned by 360 * i / 6 (duplicateMovieClip)
}
RED = dict(mult=[1.0, 1.0, 1.0, 1.0], add=[255, 0, 0, 0])    # Hero.setColor(mc, 0xFF0000)

E = C.Exporter(G, SRC, '', CUSTOM_G)
E.clip_res = [0.5, 1.0, 1.5, 2.0]
E.strategy_for = {141: 'flat', 154: 'flat', 188: 'flat'}

E.export(219, 'hero', strategy='flat')
E.export(62, 'death', strategy='flat')
E.export(189, 'monster', strategy='flat', code=('sub',))
E.export(211, 'tir', code=('skin',))
E.export(211, 'tirRed', cx=RED, frames=[1])
E.export(108, 'plop', code=('sub',))
E.export(108, 'plopRed', code=('sub',), cx=RED)
E.export(115, 'heliPart', strategy='flat', frames=[1, 2, 3, 4, 5])
E.export(239, 'boum', strategy='flat')
E.export(13, 'blam', strategy='flat')
E.export(36, 'comment', code=('c',))
E.export(96, 'bonus', frames=[1, 2, 3, 4, 5])

# bonus: frames 1-3 (points) show the sparkling gem (sprite 94) under 3 colour transforms with negative offsets, frame 4
# (speed) the option (sprites 16, 19) under 2 more: no tint + added colour can do them, one baked variant each. The
# nested clips are named for the code (their playheads give the bounds of the bonus, see meta 'bonus*').
bonus = E.clips['bonus']
lay = {L['a']: L for L in bonus['layers']}
assert set(lay) == {'c94', 'bonus_1', 'c16', 'c19', 'c24'}, set(lay)
n = bonus['n']


def frame_cx(sid, f, child):
    inst = R.Instance(G, sid, ctrl={sid: f, '__noactions__': True})
    return [e for e in inst.display.values() if e['inst'] is not None and e['inst'].sid == child][0]['cx']


def only(frames, L, a, nm):
    return dict(L, a=a, nm=nm, p=[(L['p'][i] if i + 1 in frames else 0) for i in range(n)])


layers = []
for f in (1, 2, 3):
    a = E.export(94, 'gem%d' % f, cx=frame_cx(96, f, 94), res=E.clips['c94']['r'])
    layers.append({k: v for k, v in only([f], lay['c94'], a, 'gem').items() if k not in ('ads', 'tns', 'tn', 'ad')})
layers.append(lay['bonus_1'])
for sid in (16, 19):
    L = lay['c%d' % sid]
    a = E.export(sid, 'opt%d' % sid, cx=frame_cx(96, 4, sid), res=E.clips['c%d' % sid]['r'])
    layers.append({k: v for k, v in only([4], L, a, 'o%d' % sid).items() if k not in ('ads', 'tns', 'tn', 'ad')})
    layers.append({k: v for k, v in only([5], L, 'c%d' % sid, 'o%d' % sid).items() if k not in ('ads', 'tns', 'tn', 'ad')})
layers.append(dict(lay['c24'], nm='o24'))
bonus['layers'] = layers

Ep = C.Exporter(Gp, SRC, 'p', {})
Ep.export(222, 'bg', strategy='flat', res=0.5)

# clips no longer used (the gem under its tint + added colour) and their images
ROOTS = ['hero', 'death', 'monster', 'tir', 'tirRed', 'plop', 'plopRed', 'heliPart', 'boum', 'blam', 'comment', 'bonus']
keep, todo = set(), list(ROOTS)
while todo:
    nm = todo.pop()
    if nm in keep:
        continue
    keep.add(nm)
    todo += [L['a'] for L in E.clips[nm]['layers'] if L['k'] == 2]
used = {L['a'] for nm in keep for L in E.clips[nm]['layers'] if L['k'] != 2}
for nm in [nm for nm in E.clips if nm not in keep]:
    for L in E.clips.pop(nm)['layers']:
        if L['k'] != 2 and L['a'] not in used:
            for a in (L['a'], L['a'] + 'W'):
                if a in E.area:
                    shutil.rmtree(os.path.join(SRC, a))
                    E.area.pop(a)
                    E.pivots.pop(a)
    print('  unused clip %s removed' % nm)

clips, pivots, area = {}, {}, {}
for X in (E, Ep):
    for k in X.clips:
        assert k not in clips, k
    clips.update(X.clips)
    pivots.update(X.pivots)
    area.update(X.area)

meta = {}

# ---------------------------------------------------------------- bounds read by the hitTests (Std.hitTest = Flash
# MovieClip.hitTest(target): overlap of the two clips' bounds in the stage). Flash bounds: every shape rectangle through
# its full matrix (Renderer.bounds), in the coordinates of the clip the code moves. Untouched timelines (Gb): the morph
# shape of the fireball lies inside its plain shape on every frame (checked below).
def path_bounds(sid, ctrl, path, M=R.IDENT, hide=()):
    """bounds of the instance reached by `path` (instance names) in sprite `sid` with frames forced by `ctrl`"""
    inst = R.Instance(Gb, sid, ctrl=dict(ctrl, __noactions__=True))
    for name in path:
        e = [x for x in inst.display.values() if x['name'] == name][0]
        M = R.mat_mul(M, e['matrix'])
        inst = e['inst']
    rd = R.Renderer(Gb, 1)
    cmds = []
    rd.collect(inst, M, R.NOCX, set(hide), cmds)
    b = rd.bounds(cmds)
    return [round(b[0], 4), round(b[2], 4), round(b[1], 4), round(b[3], 4)]    # xMin xMax yMin yMax


def leaves(sid, ctrl, M=R.IDENT):
    """the shapes drawn by a sprite: [xMin, xMax, yMin, yMax (shape), a, b, c, d, tx, ty (matrix in the sprite)]"""
    inst = R.Instance(Gb, sid, ctrl=dict(ctrl, __noactions__=True))
    rd = R.Renderer(Gb, 1)
    cmds = []
    rd.collect(inst, M, R.NOCX, set(), cmds)
    out = []
    for c in cmds:
        assert c[0] == 'shape', c[0]
        r, m = Gb.shapes[c[1]], c[2]
        if c[1] in Gb.morphs:
            continue
        out.append([round(v, 4) for v in list(r) + [m['a'], m['b'], m['c'], m['d'], m['tx'], m['ty']]])
    return out


# hero.mc.col: the same on every frame of the hero
hc = {tuple(path_bounds(219, {219: f}, ['col'])) for f in range(1, 61)}
assert len(hc) == 1, hc
meta['heroCol'] = list(hc.pop())
# monster.mc.sub.col for each type (frame of mc) and frame of sub
meta['monsterCol'] = [[path_bounds(189, {189: t + 1, 'sub': f}, ['sub', 'col']) for f in range(1, Gb.sprites[sid].nframes + 1)]
                      for t, sid in enumerate((141, 154, 188))]
# tir (turned by its _rotation): the shapes of each frame of tir and of its nested clip
TIR_NESTED = {1: None, 2: 202, 3: 207, 4: 210}
meta['tirLeaves'] = []
for tf in range(1, 5):
    sub = TIR_NESTED[tf]
    nf = Gb.sprites[sub].nframes if sub else 1
    meta['tirLeaves'].append([leaves(211, {211: tf, sub: f} if sub else {211: tf}) for f in range(1, nf + 1)])
for f in range(1, 11):
    inst = R.Instance(Gb, 202, ctrl={202: f, '__noactions__': True})
    rects = {d: Gb.shapes[e['char']] for d, e in inst.display.items()}
    for d, r in rects.items():
        if inst.display[d]['char'] in Gb.morphs:
            assert all(r[0] >= o[0] and r[1] <= o[1] and r[2] >= o[2] and r[3] <= o[3]
                       for dd, o in rects.items() if dd != d), ('fireball morph outside', f)
# bonus: points (frames 1-3): the gem (sprite 94) at each of its frames with the static shape; options (frames 4-5):
# sprite 16, sprite 19, and the 7 particles (sprite 23: "a" and its 6 copies turned by 60 deg) at each of their frames
for f in (1, 2, 3):
    assert path_bounds(96, {96: f, 94: 1}, []) == path_bounds(96, {96: 1, 94: 1}, [])
meta['bonusGem'] = [path_bounds(96, {96: 1, 94: f}, []) for f in range(1, 31)]
meta['bonus16'] = [path_bounds(96, {96: 4, 16: f}, [], hide=(19, 24)) for f in range(1, 22)]
meta['bonus19'] = [path_bounds(96, {96: 4, 19: f}, [], hide=(16, 24)) for f in range(1, 24)]
assert meta['bonus16'] == [path_bounds(96, {96: 5, 16: f}, [], hide=(19, 24)) for f in range(1, 22)]
inst = R.Instance(Gb, 96, ctrl={96: 4, '__noactions__': True})
M24 = [e for e in inst.display.values() if e['inst'] is not None and e['inst'].sid == 24][0]['matrix']
inst24 = R.Instance(Gb, 24, ctrl={'__noactions__': True})
Ma = R.mat_mul(M24, [e for e in inst24.display.values() if e['name'] == 'a'][0]['matrix'])
meta['bonusPart'] = []
for i in range(6):
    r = math.radians(360 * i / 6)
    rot = dict(a=math.cos(r), b=math.sin(r), c=-math.sin(r), d=math.cos(r), tx=0, ty=0)
    meta['bonusPart'].append([path_bounds(23, {23: f}, [], M=R.mat_mul(Ma, rot)) for f in range(1, 40)])
print('heroCol', meta['heroCol'])
json.dump(clips, open(os.path.join(OUT, 'clips.json'), 'w'), separators=(',', ':'))
json.dump(pivots, open(os.path.join(OUT, 'pivots.json'), 'w'), indent=0)
json.dump(meta, open(os.path.join(OUT, 'meta.json'), 'w'), indent=1)
tot = sum(area.values())
print('clips %d, anims %d, trimmed area %.2f Mpx, warnings %d' % (len(clips), len(area), tot / 1e6, E.warnings + Ep.warnings))
for k, v in sorted(area.items(), key=lambda x: -x[1])[:30]:
    print('  %-24s %8d px' % (k, v))
