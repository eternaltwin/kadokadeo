#!/bin/sh
# K-Slash: SWF -> images + timeline tables -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/kslash kslash gfx decor
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/kslash"
cd "$W"
python3 "$HERE/kslash_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|unused|clips [0-9]|shade colour" assets.log || true
python3 "$HERE/kslash_data.py" "$W/out" "$REPO/resources/hx/games/kslash/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/kslash out/pivots.json | tail -1
D="$REPO/public/assets/img/content/kslash"
rm -rf "$D" && mkdir -p "$D"
cp sheet/kslash-*.json sheet/kslash-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/kslash.tps" kslash
