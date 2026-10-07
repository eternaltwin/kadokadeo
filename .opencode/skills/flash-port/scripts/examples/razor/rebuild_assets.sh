#!/bin/sh
# Razor: SWF -> images + timeline tables -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/Razor razor gfx
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/razor"
cd "$W"
python3 "$HERE/razor_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/razor_data.py" "$W/out" "$REPO/resources/hx/games/razor/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/razor out/pivots.json | tail -1
D="$REPO/public/assets/img/content/razor"
rm -rf "$D" && mkdir -p "$D"
cp sheet/razor-*.json sheet/razor-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/razor.tps" razor
# start screen: a candidate of rart.mjs (PAT=b: "ARCHI-GORE!"), when it was made
[ -f "$W/art/b17.png" ] && python3 "$HERE/razor_artwork.py" b17 "$REPO/public/assets/img/gfx/artwork/razor.jpg" || true
