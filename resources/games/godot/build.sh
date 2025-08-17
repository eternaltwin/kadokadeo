#!/bin/bash

cp /app/godot/bin/.web_zip/* /www/public/gamesdata

find * -type d -prune | while read -r d; do
    if [ "$d" = "output" ]; then continue; fi;
    echo "Processing game $d";
    python3 set_template.py /app/godot/bin/godot.web.template_release.wasm32.nothreads.zip --file "$d/export_presets.cfg" --debug /app/godot/bin/godot.web.template_release.wasm32.nothreads.zip;
    /app/godot/bin/godot.linuxbsd.editor.arm64 --headless --path $d --export-release "Web" /www/resources/games/godot/output/$d;
    mv output/$d.pck /www/public/gamesdata;
    rm output/*;
done
