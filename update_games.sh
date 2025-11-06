#!/bin/sh

set -e

cd /www/resources/games/godot

git config --global url."https://".insteadOf git@
git submodule update --init --recursive
git submodule update --recursive --remote

find * -type d -prune | while read -r d; do
    if [ "$d" = "output" ]; then continue; fi;
    echo "Processing game $d";
    python3 set_template.py /godot/godot.web.template_release.wasm32.nothreads.zip --file "$d/export_presets.cfg" --debug /godot/godot.web.template_release.wasm32.nothreads.zip;
    /godot/godot --headless --path $d --export-release "Web" /www/resources/games/godot/output/$d;
    mv output/$d.pck /www/public/gamesdata/$d.pck;
    rm output/*;
done
