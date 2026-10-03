#!/bin/sh
# Magmax: SWF -> images -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/magmax magmax gfx
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port), FFDEC (command running FFDec)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/magmax"
if [ -z "$FFDEC" ]; then
  if [ -f /Applications/FFDec.app/Contents/Resources/ffdec.jar ]; then FFDEC="java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar"
  elif command -v ffdec-cli.exe >/dev/null 2>&1; then FFDEC=ffdec-cli.exe
  else FFDEC=ffdec; fi
fi
cd "$W"
# the sprites drawn with morph shapes (lava blob, fireball), frame by frame
if [ ! -d spr4_gfx ]; then
  $FFDEC -onerror ignore -format sprite:png -zoom 4 -selectid 165,202 -export sprite spr4_gfx gfx.swf > ffspr4_gfx.log 2>&1
fi
python3 "$HERE/magmax_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/magmax_data.py" "$W/out" "$REPO/resources/hx/games/magmax/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/magmax out/pivots.json | tail -1
D="$REPO/public/assets/img/content/magmax"
rm -rf "$D" && mkdir -p "$D"
cp sheet/magmax-*.json sheet/magmax-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/magmax.tps" magmax
