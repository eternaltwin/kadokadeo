# Hammerfest: the generator of levels alone

The levels of Hammerfest are made at random by `resources/hx/games/hammerfest/Level*.hx`. These tools run the
generator in node, without the game, to look at many levels at once and check the rules of the design.

```sh
sh build.sh                                   # -> $KKP_WORK/build/hfgen.js (haxe -D gentest)
node run.cjs --wells 1,2,3,4,5,6,7,8,9,10 50 > wells.jsonl   # 10 wells of 50 levels, one JSON line per level
node run.cjs 7 21                             # the well of seed 7, levels 0..20
PY=~/kadokadeo-port/venv/bin/python           # (PIL)
$PY check.py wells.jsonl [-v]                 # the rules of the design: expect "HARD VIOLATIONS: 0"
$PY stats.py wells.jsonl                      # weight, bads, platforms, lasers by depth; failures; fallback levels (expect 0)
$PY sheet.py wells.jsonl sheet.png            # one row per depth, one column per well (--rows 20-29 --cell 10 --nodark)
GEN_WHY=bads GEN_AT=35 node run.cjs 7 36 2>&1 >/dev/null   # ASCII maps of the levels failing for a reason at a depth
```
Legend of the sheet: `@` Igor, letters = kinds (C cerise, o orange, P pomme, B banane, L citron, O bombino, `*` poire,
A abricot, F fraise, k kiwi, K litchi, N ananas, W blob, X scie, R framboise, `~` bondissante, red triangles = spikes),
bars = lasers (white, black, blue, green, red, violet = no bombs, cyan = teleporter), green ticks on top = the columns
Igor can come in by, veil = the darkness of the level with the light around Igor, `w` = weight of the lineup.
