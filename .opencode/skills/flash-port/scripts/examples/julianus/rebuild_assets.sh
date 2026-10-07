#!/bin/sh
# Julianus: SWF -> images -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/Julianus julianus gfx
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port), FFDEC (command running FFDec)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/julianus"
if [ -z "$FFDEC" ]; then
  if [ -f /Applications/FFDec.app/Contents/Resources/ffdec.jar ]; then FFDEC="java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar"
  elif command -v ffdec-cli.exe >/dev/null 2>&1; then FFDEC=ffdec-cli.exe
  else FFDEC=ffdec; fi
fi
cd "$W"
# the sprites drawn with morph shapes (bonus glows, pop, fxBonus), frame by frame
if [ ! -d spr4_gfx ]; then
  $FFDEC -onerror ignore -format sprite:png -zoom 4 -selectid 46,60,89,95 -export sprite spr4_gfx gfx.swf > ffspr4_gfx.log 2>&1
fi
python3 "$HERE/julianus_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|leaf|anims [0-9]" assets.log || true
mkdir -p "$REPO/resources/hx/games/julianus"
python3 "$HERE/julianus_data.py" "$W/out" "$REPO/resources/hx/games/julianus/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/julianus out/pivots.json | tail -1
D="$REPO/public/assets/img/content/julianus"
rm -rf "$D" && mkdir -p "$D"
cp sheet/julianus-*.json sheet/julianus-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/julianus.tps" julianus
python3 "$HERE/julianus_artwork.py" out "$REPO/public/assets/img/gfx/artwork/julianus.jpg"
