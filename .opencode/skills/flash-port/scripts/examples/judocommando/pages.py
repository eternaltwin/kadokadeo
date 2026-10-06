"""Writes pages.json (next to this file): the clips of Judo Commando on a grid, as the game draws them (4 px per Flash
pixel: the map is zoomed x2). Each item: [clip, frame or label, x, y, scale, {path of a nested clip: frame}, {var: n}]
(paths: "smc", "smc.smc"; vars: _hfr / _bfr / _gfr of the soldiers on root.smc, _afr on the hero). Read by ref.py (SWF)
and ncheck.mjs (game)."""
import json, os
HERE = os.path.dirname(os.path.abspath(__file__))
TYPES = {'Standard': (1, {'hfr': 4, 'bfr': 2, 'gfr': 2}), 'Soldat': (2, {'hfr': 1, 'bfr': 2, 'gfr': 1}),
         'Sapper': (3, {'hfr': 2, 'bfr': 1, 'gfr': 1}), 'Heavy': (4, {'hfr': 1, 'bfr': 3, 'gfr': 2})}
items = []
H = lambda lab, sub=None, v=None: items.append(['mcHero', lab, 0, 0, 2, sub or {}, v or {}])
for lab in ('stand', 'standQuiet', 'land', 'run', 'jump', 'jumpDown', 'grapple', 'tomoeNage', 'osotogari', 'ground',
            'stand_lift', 'throwBackward', 'heavyLand', 'knockOut', 'hitHead'):
    H(lab)
for lab, fs in (('walk', (1, 10, 20)), ('ladder', (1, 4)), ('crouch', (3,)), ('hold', (1, 15)), ('ipponSeoi', (1, 5, 9)),
                ('kataGuruma', (3, 6)), ('throwBody', (4,)), ('walk_lift', (1, 15)), ('lift', (6,)), ('hitBody', (3,)),
                ('airGrab', (5,)), ('climb', (1, 10, 20)), ('kneeGrab', (6,)), ('headCrush', (1, 13, 26)), ('hangOn', (1, 6)),
                ('hangClimb', (6,)), ('crash', (1, 6)), ('throwUpward', (7,)), ('holdBody', (3,))):
    for f in fs:
        H(lab, {'smc': f})
H('groundRoll', {'animGroundRoll': 5})
for f, afr in ((10, 1), (20, 3), (20, 4), (27, 5)):
    H('armLock', {'smc': f}, {'afr': afr})
for t, (fr, v) in TYPES.items():
    M = lambda lab, sub=None: items.append(['mcMonsters', fr, 0, 0, 2, dict({'smc': lab}, **(sub or {})), v])
    for lab in ('stand', 'grappling', 'knockOut', 'held', 'prepare', 'crouchAim', 'crashCustom'):
        M(lab)
    for lab, f in (('walk', 10), ('hitCeiling', 3), ('crash', 7), ('lifted', 4), ('crouch', 3), ('punch', 5), ('aim', 1),
                   ('kneeGrabbed', 6), ('ladder', 3), ('highKick2', 2), ('jump', 5), ('jumpDown', 8), ('crouchAimRocket', 20)):
        M(lab, {'smc.smc': f})
N = lambda lab, sub=None: items.append(['mcMonsters', 5, 0, 0, 2, dict({'smc': lab}, **(sub or {})), {}])
for lab in ('stand', 'walk', 'grappling', 'knockOut', 'held', 'lifted', 'prepare', 'kneeGrabbed'):
    N(lab)
for lab, f in (('hitCeiling', 3), ('crash', 7), ('crouch', 3), ('punch', 5), ('wheel', 10), ('jumpRoll', 4), ('highKick', 2),
               ('highKick2', 4), ('prepareSlash', 4), ('attackSlash', 4), ('airThrow', 3), ('jumpDown', 5)):
    N(lab, {'smc.smc': f})
for lab, f in (('stand', 5), ('walk', 18), ('crouch', 1), ('highKick', 4), ('highKick2', 5), ('jump', 4), ('fatalityGrab', 6),
               ('backToNormal', 6), ('fatality0', 9), ('fatality1', 19), ('piledriver', 20), ('impact', 6)):
    items.append(['mcMonsters', 6, 0, 0, 2, {'smc': lab, 'smc.smc': f}, {}])
for lab in ('knockOut', 'crash', 'seek'):
    items.append(['mcMonsters', 6, 0, 0, 2, {'smc': lab}, {}])
S = lambda c, f, sub=None: items.append([c, f, 0, 0, 2, sub or {}, {}])
for f in (1, 2, 3):
    S('mcBonus', f)
for g in range(1, 9):
    S('mcBonus', 1, {'smc': g})
for c, fs in (('mcBullet', (1, 3)), ('mcShuriken', (1, 4)), ('mcRocket', (1, 3)), ('mcMine', (1,)), ('mcExplosion', (2, 8, 16)),
              ('mcBlood', (1, 6)), ('fxSpark', (2, 9)), ('fxSpark2', (1, 3)), ('fxSmoke', (2, 8)), ('mcVanish', (2, 6)),
              ('mcSlash', (2, 6)), ('mcSwordSlash', (2, 4)), ('fxShotImpact', (2, 7)), ('fxTwinkle', (1, 4)), ('mcNum', (1, 5, 10)),
              ('partBrick', (1, 2)), ('partWood', (1, 3)), ('fxBrickDust', (1, 4)), ('mcLifeBar', (1,)), ('mcLifePoint', (1,)),
              ('mcGem', (1, 5, 8, 11))):
    for f in fs:
        S(c, f)
for f in (2, 11):
    S('mcLevel', 1, {'smc': f})
COLS, ROWS = 6, 7
pages = []
for i, it in enumerate(items):
    p, k = divmod(i, COLS * ROWS)
    if k == 0:
        pages.append([])
    r, c = divmod(k, COLS)
    it[2], it[3] = 50 + c * 100, 50 + r * 90
    pages[-1].append(it)
json.dump(pages, open(os.path.join(HERE, 'pages.json'), 'w'), separators=(',', ':'))
print(len(items), 'items', len(pages), 'pages')
