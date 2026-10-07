#!/bin/sh
# The original Aqua Splash in Ruffle, for side by side comparisons with the port (ruf.mjs): the server of
# ../klinkersurprise/ruffle, its ruffle/ref.html (a frame rate can be given) and ref.swf (ref_swf.py) served on port $1 (8783).
# usage: sh ruffle_site.sh [port]      then http://127.0.0.1:8783/ref.html?swf=ref.swf
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
KR="$HERE/../klinkersurprise/ruffle"
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
V="$WORK/vendor/ruffle"
if [ ! -f "$V/package/ruffle.js" ]; then
  mkdir -p "$V" && (cd "$V" && npm pack @ruffle-rs/ruffle@0.6.0 && tar xzf ruffle-rs-ruffle-0.6.0.tgz)
fi
W="$WORK/aquasplash"
[ -f "$W/ref.swf" ] || python3 "$HERE/ref_swf.py"
S="$W/rufflesite"
mkdir -p "$S"
ln -sfn "$V/package" "$S/ruffle"
cp "$HERE/ruffle/ref.html" "$S/ref.html"
for f in "$W"/ref*.swf; do ln -sf "$f" "$S/$(basename "$f")"; done
cd "$S" && exec python3 "$KR/serve.py" "${1:-8783}"
