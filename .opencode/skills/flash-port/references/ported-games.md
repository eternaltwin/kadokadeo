# Ports made with this method: where to look

Code in `resources/hx/games/<game>/`. Only K-Slash's tooling is kept in `scripts/examples/`. The asset scripts
of the other games (`tools/manda_data.py`, `knight_data.py`, `piou_data.py`, `minirace_data.py`... named in the
header of their `Data.hx`) are not in the repository: their `Data.hx` and sheets cannot be regenerated from here.
To change their graphics, write a new `<game>_assets.py` / `<game>_data.py` from the K-Slash model.

| Game (package) | Kind | Look at it for |
|---|---|---|
| K-Slash (`kslash`) | platform action, keyboard | **the reference**: [kslash-walkthrough.md](kslash-walkthrough.md); the most complete `Clip.hx` (AVM1 order of first-frame scripts, `flushRemoved`, `noFlipLerp`), afterimages as tinted white silhouettes, bitmaps at native resolution, platforms without a mask (`PlatGfx.hx`), NIGHT code as a replay event, joystick + buttons, test mode `modes/kslash.js`, comparison pages |
| Manda (`manda`) | snake, keyboard | no Clip pipeline (simple renders + bounds in `Data.hx`), one container per plane (`Plans.hx`), the snake drawn as a mesh (`SnakeGfx.hx`), a mask replaced by drawing the decor on top, rounding of trigonometry, statics reset |
| Kanji's Nightmare (`kanjisnightmare`) | platform | the first Clip runtime, `Digits.hx` (numbers in the SWF font), `warmShaders`, `Sprite.setRoot(mc, true)` (interpolation kept when a sprite changes) |
| Pioutch (`pioutch`) | skill game | made from the **released** SWF (archive SWF different, names obfuscated, code decompiled), `Clip.runLater` (frame scripts after a `goto` of the code), blend modes and filters baked per clip |
| Mini-Race (`minirace`) | racing, mouse | mouse capture (`setPointerCapture`), finger = mouse on touch screens, glows baked, light streaks as `NineSlicePlane`, skid marks painted in a RenderTexture during `update`, `hitTest` replaced by a run-length mask |
| Iron Chouquette (`ironchouquette`) | shooter | plasma trails rewritten for mobile (`PlasmaLayer.hx`: batched stamps + one shader pass), gameplay reading a CPU copy instead of GPU pixels (`SpeedField.hx`) |
| Kanji's Adventure (`kanjisadventure`) | turn-based roguelike | a full bot (stairs, items, fights, bag, shop), `Ent.display(true)`, many monsters on screen; older `S()` / `I()` scaling |
| Ellon in the Dark (`elloninthedark`) | action | nested animations, score text, tentacle strokes; the `null` pitfall (Golgoth `shootRate`); older `S()` / `I()` scaling |
| Xian Xiang (`xianxiang`) | puzzle, mouse | the simplest port |
| Paradice (`paradice`) | puzzle, keyboard | a 40 frames/s original emulated in the game (5 Flash frames per 4 steps, clips shown one Flash frame late, `MC.hx` / `Clip.hx` from Magmax), a random body frame that is game state (`Clip.randomB`), bitmaps at native resolution inside clips (`Exporter.bitmaps`), text fields as glyph images including a device font (`Txt.hx`), whitening by tint + additive silhouette (`MC.setPercentColor`), tooling in `scripts/examples/paradice/` |

Shared code these ports added to `resources/hx/lib` (now on `main`): key aliases and the floating joystick
(`KeyboardManager`, `TouchControlsOverlay`, `TouchControlsConfig`), replay format v3, seeking and the replay
player controls (`ReplayManager`, `ReplayHud`, `KadoKadeoManager`), no pause when the tab is hidden.

The other games of the repository (alchimie, atlanteine, bactery...) were ported earlier with the `.opencode`
conversion skills and `S()` / `I()` scaling: useful for the API, less for faithfulness to the original.
