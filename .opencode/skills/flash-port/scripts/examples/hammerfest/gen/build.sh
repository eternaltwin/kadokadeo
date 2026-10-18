#!/bin/sh
# The generator of the levels of Hammerfest alone, for node: $KKP_WORK/build/hfgen.js (run with run.cjs).
# usage: sh build.sh        env: KKP_WORK (default ~/kadokadeo-port), HAXE (default haxe)
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../../../../../.." && pwd)
WORK=${KKP_WORK:-$HOME/kadokadeo-port}
mkdir -p "$WORK/build"
cd "$REPO"
${HAXE:-haxe} -L pixijs -L crypto -L jsImport -cp ./resources/hx/lib -cp ./resources/hx/games -cp "$HERE" \
    -main hammerfest.GenTest -js "$WORK/build/hfgen.js" -dce full -D gentest
# (the ES imports of the libraries: the stubs of run.cjs stand for them)
perl -ni -e 'print unless /^import /' "$WORK/build/hfgen.js"
echo GEN_OK
