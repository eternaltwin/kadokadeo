#!/bin/sh
# Quadrikolor: SWF -> images + timeline tables -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh <WebGamesArchives>/KadoKado/Games/quadrikolor quadrikolor gfx
# usage: sh rebuild_assets.sh          env: KKP_WORK (default ~/kadokadeo-port), FFDEC (see prepare_game.sh)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/quadrikolor"
cd "$W"
# the static texts as SVG (exact glyph outlines), drawn like shapes by quadrikolor_assets.py
if [ ! -d txt_gfx ]; then
  if [ -z "$FFDEC" ]; then
    if [ -f /Applications/FFDec.app/Contents/Resources/ffdec.jar ]; then FFDEC="java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar"
    elif command -v ffdec-cli.exe >/dev/null 2>&1; then FFDEC=ffdec-cli.exe
    else FFDEC=ffdec; fi
  fi
  $FFDEC -onerror ignore -format text:svg -export text txt_gfx gfx.swf > fftxt_gfx.log 2>&1
fi
python3 "$HERE/quadrikolor_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/quadrikolor_data.py" "$W/out" "$REPO/resources/hx/games/quadrikolor/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/quadrikolor out/pivots.json | tail -1
D="$REPO/public/assets/img/content/quadrikolor"
rm -rf "$D" && mkdir -p "$D"
cp sheet/quadrikolor-*.json sheet/quadrikolor-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/quadrikolor.tps" quadrikolor
# start screen (SWF renders)
if [ -f "$HERE/quadrikolor_artwork.py" ]; then
  python3 "$HERE/quadrikolor_artwork.py" "$REPO/public/assets/img/gfx/artwork/quadrikolor.jpg"
fi
