#!/bin/sh
# Start screen of Pacifik (public/assets/img/gfx/artwork/pacifik.jpg, 600 x 600): a moment of a game drawn by the port
# from the SWF pictures (glows and particles included), like the old thumbnail (assets/img/games/Pacifik.png: the
# ship with its smoke, the laser, sparks, balls, canons): step 250 of artwork_replay.txt (a p3.mjs game with
# '&test=pk&full=1&learn=3&ship=60&frames=700': 12 canons a side, every ball colour, an early ship), the game alone.
# Needs the harness: sh ../../harness/build.sh pacifik, and server.py on $HPORT.
# usage: HPORT=8811 sh pacifik_artwork.sh
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../../../../../.." && pwd)
W="${KKP_WORK:-$HOME/kadokadeo-port}/pacifik"
cd "$HERE"
NOHUD=1 PORT=${PORT:-9938} node --experimental-websocket pshots.mjs artwork_replay.txt '&test=pk&full=1&learn=3&ship=60&frames=700' artwork 250 2>&1 | grep -v ExperimentalWarning || true
python3 -c "
from PIL import Image
Image.open('$W/shots/artwork_250.png').convert('RGB').save('$REPO/public/assets/img/gfx/artwork/pacifik.jpg', quality=92)"
echo "artwork: $REPO/public/assets/img/gfx/artwork/pacifik.jpg"
