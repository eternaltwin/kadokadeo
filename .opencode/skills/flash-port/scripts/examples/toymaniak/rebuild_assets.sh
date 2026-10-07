#!/bin/sh
# Toy Maniak: SWF -> images -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/toymaniak toymaniak gfx toymania
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port), FFDEC (command running FFDec)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/toymaniak"
cd "$W"
python3 "$HERE/toymaniak_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|anims [0-9]" assets.log || true
python3 "$HERE/toymaniak_data.py" "$W/out" "$REPO/resources/hx/games/toymaniak/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/toymaniak out/pivots.json | tail -1
D="$REPO/public/assets/img/content/toymaniak"
rm -rf "$D" && mkdir -p "$D"
cp sheet/toymaniak-*.json sheet/toymaniak-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/toymaniak.tps" toymaniak
python3 "$HERE/toymaniak_artwork.py" "$W/out" "$REPO/public/assets/img/gfx/artwork/toymaniak.jpg"
