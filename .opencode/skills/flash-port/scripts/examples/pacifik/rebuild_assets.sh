#!/bin/sh
# Pacifik: SWF -> images -> Data.hx -> sprite sheets, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/pacifik pacifik gfx game
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port); needs rsvg-convert, Tahoma Bold.ttf
# Two sheets: pacifik-N (vector pictures, smoothed) and pacifikb-N (the bitmaps of the SWF, drawn without smoothing by
# the game), the second listed in the related_multi_packs of pacifik-0.json (loaded with it).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/pacifik"
cd "$W"
python3 "$HERE/pacifik_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|anims [0-9]" assets.log || true
python3 "$HERE/pacifik_data.py" "$W/out" "$REPO/resources/hx/games/pacifik/Data.hx"
# the two families of pictures in two folders
rm -rf split && mkdir -p split/v split/b
python3 - <<'PY'
import json, os, shutil
bm = json.load(open('out/bitmaps.json'))
for d in os.listdir('out/src'):
    shutil.copytree(os.path.join('out/src', d), os.path.join('split', 'b' if d in bm else 'v', d))
PY
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" split/v sheet/pacifik out/pivots.json | tail -1
PACK_MAX=2040 python3 "$T/pack_multi.py" split/b sheet/pacifikb out/pivots.json | tail -1
python3 - <<'PY'
import json, glob
extra = sorted(p.split('/')[-1] for p in glob.glob('sheet/pacifikb-*.json'))
j = json.load(open('sheet/pacifik-0.json'))
rel = j['meta'].get('related_multi_packs', [])
j['meta']['related_multi_packs'] = rel + [e for e in extra if e not in rel]
json.dump(j, open('sheet/pacifik-0.json', 'w'), indent=1)
PY
D="$REPO/public/assets/img/content/pacifik"
rm -rf "$D" && mkdir -p "$D"
cp sheet/pacifik*-*.json sheet/pacifik*-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" split/v out/pivots.json "$D/pacifik.tps" pacifik
python3 "$T/make_tps.py" "$T/tpl.tps" split/b out/pivots.json "$D/pacifikb.tps" pacifikb
# start screen: pacifik_artwork.sh (a moment of a game drawn by the port, needs the harness)
