#!/bin/sh
# The original game in Ruffle, for side by side comparisons with the port (../ruf.mjs):
#   - Ruffle 0.6.0 self-hosted (npm) in $KKP_WORK/vendor/ruffle (downloaded once);
#   - host.swf built from Host.hx (Haxe 4: the KadoKado AS3 loader reduced to what the game needs), it loads game.swf;
#   - served with ref.html on port $1 (8813).
# usage: sh ruffle_site.sh [port]      then http://127.0.0.1:8813/ref.html (?fixed=1: fixed step, see Host.hx)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
V="$WORK/vendor/ruffle"
if [ ! -f "$V/package/ruffle.js" ]; then
  mkdir -p "$V" && (cd "$V" && npm pack @ruffle-rs/ruffle@0.6.0 && tar xzf ruffle-rs-ruffle-0.6.0.tgz)
fi
W="$WORK/happyptitank"
S="$W/ruffle/site"
mkdir -p "$S"
haxe -cp "$HERE" -main Host -swf "$S/host.swf" -swf-version 10 -D swf-header=300:300:30:FFFFFF
ln -sfn "$V/package" "$S/ruffle"
cp "$HERE/ref.html" "$S/ref.html"
ln -sf "$W/game.swf" "$S/game.swf"
cd "$S" && exec python3 "$HERE/serve.py" "${1:-8813}"
