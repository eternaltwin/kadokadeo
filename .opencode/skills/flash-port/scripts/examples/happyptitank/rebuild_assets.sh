#!/bin/sh
# Happy Pti Tank: SWF -> pictures + timeline tables -> Data.hx -> sprite sheets, written into this repository.
# Once: sh ../../tools/prepare_game.sh <dir with swf/tank.swf (= gfx/tank.swf of the archive)> happyptitank tank
#       then in $KKP_WORK/happyptitank: the shapes at zoom 8 and the static texts as SVG (FFDec):
#       ffdec -onerror ignore -format shape:png -zoom 8 -export shape shp8_tank tank.swf
#       ffdec -onerror ignore -format text:svg -export text txtsvg_tank tank.swf
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/happyptitank"
cd "$W"
rm -rf out
python3 "$HERE/happyptitank_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|symbols [0-9]" assets.log || true
python3 "$HERE/happyptitank_data.py" "$W/out" "$REPO/resources/hx/games/happyptitank/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/happyptitank out/pivots.json | tail -1
D="$REPO/public/assets/img/content/happyptitank"
rm -rf "$D" && mkdir -p "$D"
cp sheet/happyptitank-*.json sheet/happyptitank-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/happyptitank.tps" happyptitank
