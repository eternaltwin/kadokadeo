#!/bin/sh
# K-Train: SWF -> images + timeline tables -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/Train ktrain
#       then the shapes at zoom 2 (the resolution of the textures, composed with nearest sampling):
#       $FFDEC -onerror ignore -format shape:png -zoom 2 -export shape shp2_gfx gfx.swf   (in $KKP_WORK/ktrain)
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/ktrain"
cd "$W"
python3 "$HERE/ktrain_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/ktrain_data.py" "$W/out" "$REPO/resources/hx/games/ktrain/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/ktrain out/pivots.json | tail -1
D="$REPO/public/assets/img/content/ktrain"
rm -rf "$D" && mkdir -p "$D"
cp sheet/ktrain-*.json sheet/ktrain-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/ktrain.tps" ktrain
# start screen (SWF renders: a moment of a game)
[ -f "$HERE/ktrain_artwork.py" ] && python3 "$HERE/ktrain_artwork.py" out "$REPO/public/assets/img/gfx/artwork/ktrain.jpg"
