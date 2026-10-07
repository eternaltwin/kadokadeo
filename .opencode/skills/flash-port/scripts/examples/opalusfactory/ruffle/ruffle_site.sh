#!/bin/sh
# The original game in Ruffle, for side by side comparisons with the port (klinkersurprise/ruf_live.mjs):
#   - Ruffle 0.6.0 self-hosted (npm) in $KKP_WORK/vendor/ruffle (downloaded once);
#   - ref.swf (and the ref_<name>.swf variants already made by ../ref_swf.py) served with ref.html on port $1 (8782).
# usage: sh ruffle_site.sh [port]      then http://127.0.0.1:8782/ref.html?swf=ref.swf
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
V="$WORK/vendor/ruffle"
if [ ! -f "$V/package/ruffle.js" ]; then
  mkdir -p "$V" && (cd "$V" && npm pack @ruffle-rs/ruffle@0.6.0 && tar xzf ruffle-rs-ruffle-0.6.0.tgz)
fi
W="$WORK/opalusfactory"
[ -f "$W/ref.swf" ] || python3 "$HERE/../ref_swf.py"
S="$W/rufflesite"
mkdir -p "$S"
ln -sfn "$V/package" "$S/ruffle"
cp "$HERE/../../klinkersurprise/ruffle/ref.html" "$S/ref.html"
for f in "$W"/ref*.swf; do ln -sf "$f" "$S/$(basename "$f")"; done
cd "$S" && exec python3 "$HERE/../../klinkersurprise/ruffle/serve.py" "${1:-8782}"
