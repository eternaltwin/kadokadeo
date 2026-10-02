#!/bin/sh
# Work folder of a port: copies the SWF files of an archive game into $KKP_WORK/<pkg>/ and exports them with JPEXS
# FFDec (everything the asset scripts read). Keep the logs: FFDec prints the ids of what it exported.
# usage: sh prepare_game.sh <archive game folder> <pkg> [swf name...]
#   e.g. sh prepare_game.sh ~/code/WebGamesArchives/KadoKado/Games/kslash kslash gfx decor
#   (no swf names: every swf/*.swf of the game)
# For each <n>.swf, in $KKP_WORK/<pkg>/:
#   shp4_<n>/   shapes as PNG at zoom 4 (read by swfrender: composed at x4, reduced to x2)
#   shp1_<n>/   shapes at zoom 1 (bitmap fills at their native resolution)
#   svg_<n>/    shapes as SVG (matrices of the bitmap fills, curves)
#   img_<n>/    bitmaps         fonts_<n>/  embedded fonts (.ttf)        as_<n>/  decompiled AS2 (frame scripts)
#   dump_<n>.txt  swfdump.py: exported symbols, timelines, matrices, colour transforms
# env: KKP_WORK (default ~/kadokadeo-port), FFDEC (command running the FFDec CLI; default: the macOS app with java,
#      ffdec-cli.exe on Windows, ffdec on Linux)
set -e
SRC="$1"; G="$2"
if [ -z "$G" ]; then sed -n 2,15p "$0"; exit 1; fi
shift 2
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
D="$WORK/$G"
mkdir -p "$D"
if [ -z "$FFDEC" ]; then
  if [ -f /Applications/FFDec.app/Contents/Resources/ffdec.jar ]; then FFDEC="java -jar /Applications/FFDec.app/Contents/Resources/ffdec.jar"
  elif command -v ffdec-cli.exe >/dev/null 2>&1; then FFDEC=ffdec-cli.exe
  else FFDEC=ffdec; fi
fi
if [ $# -eq 0 ]; then
  for f in "$SRC"/swf/*.swf; do set -- "$@" "$(basename "$f" .swf)"; done
fi
cd "$D"
for n in "$@"; do
  cp "$SRC/swf/$n.swf" "$D/$n.swf"
  echo "== $n.swf -> $D"
  $FFDEC -onerror ignore -format shape:png -zoom 4 -export shape "shp4_$n" "$n.swf" > "ffshp4_$n.log" 2>&1
  $FFDEC -onerror ignore -format shape:png -zoom 1 -export shape "shp1_$n" "$n.swf" > "ffshp1_$n.log" 2>&1
  $FFDEC -onerror ignore -format shape:svg -export shape "svg_$n" "$n.swf" > "ffsvg_$n.log" 2>&1
  $FFDEC -onerror ignore -export image "img_$n" "$n.swf" > "ffimg_$n.log" 2>&1
  $FFDEC -onerror ignore -export font "fonts_$n" "$n.swf" > "fffont_$n.log" 2>&1
  $FFDEC -onerror ignore -export script "as_$n" "$n.swf" > "ffas_$n.log" 2>&1
  python3 "$HERE/swfdump.py" "$n.swf" > "dump_$n.txt"
  echo "   shapes $(ls "shp4_$n" 2>/dev/null | wc -l | tr -d ' '), images $(ls "img_$n" 2>/dev/null | wc -l | tr -d ' '), fonts $(ls "fonts_$n" 2>/dev/null | wc -l | tr -d ' ')"
done
