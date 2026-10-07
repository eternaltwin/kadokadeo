#!/bin/sh
# Cereal Punk: SWF -> images + timeline tables -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/cerealpunk cerealpunk gfx
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/cerealpunk"
cd "$W"
python3 "$HERE/cerealpunk_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/cerealpunk_data.py" "$W/out" "$REPO/resources/hx/games/cerealpunk/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/cerealpunk out/pivots.json | tail -1
D="$REPO/public/assets/img/content/cerealpunk"
rm -rf "$D" && mkdir -p "$D"
cp sheet/cerealpunk-*.json sheet/cerealpunk-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/cerealpunk.tps" cerealpunk
# start screen (SWF renders: a moment of a game)
python3 "$HERE/cerealpunk_artwork.py" "$REPO/public/assets/img/gfx/artwork/cerealpunk.jpg"
