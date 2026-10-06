#!/bin/sh
# Judo Commando: SWF -> images -> Data.hx -> sprite sheet, written into this repository.
# Once: sh ../../tools/prepare_game.sh "<WebGamesArchives>/KadoKado/Games/Judo Commando" judocommando gfx
#       then the shapes at zoom 2 (the resolution of the textures, composed with nearest sampling):
#       $FFDEC -onerror ignore -format shape:png -zoom 2 -export shape shp2_gfx gfx.swf   (in $KKP_WORK/judocommando)
# usage: sh rebuild_assets.sh <WebGamesArchives>/KadoKado/Games/Judo\ Commando
# env: KKP_WORK (default ~/kadokadeo-port)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
T="$HERE/../../tools"
REPO=$(cd "$HERE/../../../../../.." && pwd)
ORIG="$1"
if [ -z "$ORIG" ]; then sed -n 2,8p "$0"; exit 1; fi
W="${KKP_WORK:-$HOME/kadokadeo-port}/judocommando"
cd "$W"
python3 "$HERE/judocommando_assets.py" "$W/out" > assets.log 2>&1 || { tail -20 assets.log; exit 1; }
grep -E "WARN|clips [0-9]" assets.log || true
python3 "$HERE/judocommando_data.py" "$W/out" "$ORIG/src/Levels.data" "$REPO/resources/hx/games/judocommando/Data.hx"
rm -rf sheet && mkdir sheet
# 2040, not 2048: a power-of-two sheet gets mipmaps that bleed into the neighbouring sprites
PACK_MAX=2040 python3 "$T/pack_multi.py" out/src sheet/judocommando out/pivots.json | tail -1
D="$REPO/public/assets/img/content/judocommando"
rm -rf "$D" && mkdir -p "$D"
cp sheet/judocommando-*.json sheet/judocommando-*.png "$D/"
cp -r out/src "$D/src"
python3 "$T/make_tps.py" "$T/tpl.tps" out/src out/pivots.json "$D/judocommando.tps" judocommando
# start screen (SWF renders, after the vignette of the original)
python3 "$HERE/judocommando_artwork.py" "$REPO/public/assets/img/gfx/artwork/judocommando.jpg"
