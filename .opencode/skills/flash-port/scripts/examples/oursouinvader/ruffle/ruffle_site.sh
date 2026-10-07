#!/bin/sh
# The original game in Ruffle, for side by side comparisons with the port (oruf.mjs): Ruffle 0.6.0 self-hosted (npm,
# $KKP_WORK/vendor/ruffle, downloaded once) and ref.swf (../ref_swf.py) served with klinkersurprise's ref.html on port $1.
# usage: sh ruffle_site.sh [port]      then http://127.0.0.1:8808/ref.html?swf=ref.swf
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
KS="$HERE/../../klinkersurprise/ruffle"
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
V="$WORK/vendor/ruffle"
if [ ! -f "$V/package/ruffle.js" ]; then
  mkdir -p "$V" && (cd "$V" && npm pack @ruffle-rs/ruffle@0.6.0 && tar xzf ruffle-rs-ruffle-0.6.0.tgz)
fi
W="$WORK/oursouinvader"
[ -f "$W/ref.swf" ] || python3 "$HERE/../ref_swf.py"
S="$W/rufflesite"
mkdir -p "$S"
ln -sfn "$V/package" "$S/ruffle"
cp "$KS/ref.html" "$S/ref.html"
for f in "$W"/ref*.swf; do ln -sf "$f" "$S/$(basename "$f")"; done
cd "$S" && exec python3 "$KS/serve.py" "${1:-8808}"
