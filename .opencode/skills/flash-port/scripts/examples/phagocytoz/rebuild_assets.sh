#!/bin/sh
# Phagocytoz: SWF -> pictures + timeline tables -> Data.hx -> sprite sheets, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/Fragocytoz phagocytoz gfx
#       then in $KKP_WORK/phagocytoz (FFDec): the worm's frames (morph shapes) and the cells' shapes at zoom 8 / 16:
#       $FFDEC -onerror ignore -format sprite:png -zoom 4 -selectid 27 -export sprite spr4_gfx gfx.swf
#       $FFDEC -onerror ignore -format shape:png -zoom 8 -selectid 39,40,41 -export shape shp8_gfx gfx.swf
#       $FFDEC -onerror ignore -format shape:png -zoom 16 -selectid 43,45,46 -export shape shp16_gfx gfx.swf
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
# Two sheets: phagocytoz-N (the pictures, smoothed) and phagocytozb-N (the background bitmap, drawn without smoothing
# like Flash's Bitmap), the second listed in the related_multi_packs of phagocytoz-0.json (loaded with it).
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/phagocytoz"
cd "$W"
rm -rf out
python3 "$HERE/phagocytoz_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|symbols [0-9]" assets.log || true
python3 "$HERE/phagocytoz_data.py" "$W/out" "$REPO/resources/hx/games/phagocytoz/Data.hx"
rm -rf split && mkdir -p split/v split/b
for d in out/src/*; do
  n=$(basename "$d")
  if [ "$n" = BG ]; then cp -r "$d" split/b/; else cp -r "$d" split/v/; fi
done
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" split/v sheet/phagocytoz out/pivots.json | tail -1
PACK_MAX=2040 python3 "$T/pack_multi.py" split/b sheet/phagocytozb out/pivots.json | tail -1
python3 - <<'PY'
import json, glob
extra = sorted(p.split('/')[-1] for p in glob.glob('sheet/phagocytozb-*.json'))
j = json.load(open('sheet/phagocytoz-0.json'))
rel = j['meta'].get('related_multi_packs', [])
j['meta']['related_multi_packs'] = rel + [e for e in extra if e not in rel]
json.dump(j, open('sheet/phagocytoz-0.json', 'w'), indent=1)
PY
D="$REPO/public/assets/img/content/phagocytoz"
rm -rf "$D" && mkdir -p "$D"
cp sheet/phagocytoz*-*.json sheet/phagocytoz*-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" split/v out/pivots.json "$D/phagocytoz.tps" phagocytoz
python3 "$T/make_tps.py" "$T/tpl.tps" split/b out/pivots.json "$D/phagocytozb.tps" phagocytozb
