# Reading the original

## Contents
- What is in an archive folder
- Inventory
- Is it the released game?
- MTypes / AS2 semantics that change the game
- Flash player (AVM1) rules the code relies on

## What is in an archive folder

`WebGamesArchives/KadoKado/Games/kslash/`:

```
src/*.mt            game code (MTypes): Game.mt (main loop), Cs.mt (constants), one file per entity
swf/gfx.swf         graphics library: MovieClips exported by linkage name ("mcHero", "bonus", "inter"...)
swf/decor.swf       other graphics libraries (decor, backgrounds...)
fla/*.fla           Flash sources of the SWF files (FFDec cannot read them; the SWF is enough)
gfx/, psd/          source pictures of the artists (not always what the SWF contains: use the SWF)
swfmake.xml, obfu.v build and obfuscation settings of the original
```

Some games are ActionScript 2 (`.as`) instead of MTypes, some have several versions of a SWF, a few have no code
(decompile it, below). The game SWF itself was built from `src/`: the graphics SWF files only hold the symbols the
code attaches (`dm.attach("mcHero", DP_HERO)`).

## Inventory

Before writing code, list from the sources and from `$KKP_WORK/<game>/dump_<swf>.txt` (`prepare_game.sh`):

- every symbol the code attaches (`attach("...")`) and its id in the `EXPORTS` line of the dump;
- the frame labels the code plays (`gotoAndPlay("run")`), the frames it reaches (until the `stop` of each
  animation): only those frames are exported;
- the named children the code reads or drives (`mc.mask._xscale`, `mc.corner._x`, `inter.fieldStar`, `b1`...):
  they must stay separate in the export;
- the frame scripts of the timelines (`as_<swf>/`): `stop()`, `gotoAndPlay(random(...))`,
  `_parent.removeMovieClip()`, `_xscale = _parent._xscale`... each one becomes an action of the Clip runtime;
- text fields (`DefineEditText` in the dump, `swftext.py`) and the fonts they embed (`fonts_<swf>/`);
- what the code measures on the display (`_width`, `getBounds`, `hitTest`): gameplay cannot read the PIXI
  display, these values are exported as numbers or masks (`graphics.md`);
- the frame rate: `swfdump.py` prints the SWF header (`rate`). The graphics libraries often say 40; the games
  run at 32 (`mt.Timer.wantedFPS`), which is what KadoKadeo does. But when the SWF says 40, the Flash player
  really ran 40 frames/s with `tmod ~0.8`: everything scaled by `tmod` keeps its real-time speed, everything done
  **once per frame without `tmod`** (score per frame, counters, timeline playheads) ran 40 times per second.
  Mini-Race's `addScore(SCORE_ACCEL)` each frame lost 20% of its points until it gave 5 frames per 4 steps.
  The KadoKado loader (`api/loader.swf`, 40 frames/s) plays the game SWF: a loaded SWF runs at the rate of the root
  movie, so a game SWF that says another rate still ran at 40 (Opalus Factory's says 44).
- the filters and blend modes of the placements (PlaceObject3): `swfdump.py` does not print them; list them from
  `swfrender` (`G.sprites[sid].frames`, keys `filters` / `blend`). Opalus Factory's gradient in "overlay" mode over
  the whole roll was only found on screen.

## Is it the released game?

The archive is the developers' folder, not always what was online. For Pioutch the archive `gfx.swf` differed from
the released `pioucanon.swf`: the port was made from the released SWF, whose export and instance names are
obfuscated (mapped by hand in the asset script, with the decompiled code). When a detail looks wrong (a missing
animation, different values), compare with a video or the released SWF if one is available.

No source code (or a doubt about what the source means): decompile the released SWF,
`$FFDEC -export script as_out game.swf`. Names are obfuscated but the structure, constants and order of the
calls are readable.

## MTypes / AS2 semantics that change the game

`mt-to-haxe` covers the syntax. These are the cases where a literal conversion compiles but plays differently:

| Original | Meaning | Port |
|---|---|---|
| `for (a; c1, c2; b)` | loop while `c1` **and** `c2` (Manda's scissors cut 1, 2, 3... pieces) | `while (c1 && c2)` |
| `for (var i = 0; i < list.length; i++) list[i].update()` where `update` can remove the element (`kill` -> `list.remove(this)`) | `length` is read at each turn; the next element moves to index `i` and **waits until the next frame** | an explicit `while (i < list.length)` loop (K-Slash). Never `for (i in 0...list.length)` (length read once: reads past the end after a removal) or a loop over a copy (nothing skipped). Haxe's `for (x in list)` happens to compile to the same index loop on JS, but its behaviour when the array changes is not specified |
| the same object pushed twice in a list (K-Slash `Kunai.new` after `Shoot.new`) | updated twice per frame (twice the speed) | keep it, with a comment |
| `undefined` or `null` in arithmetic | `NaN` (SWF 7/8), every comparison with `NaN` is false | JS gives `x * null == 0`: guard any field explicitly set to `null` and used in a calculation (Ellon: `shootRate = null` made the Golgoth shoot non-stop). A Haxe field never assigned is `undefined` in JS: `NaN`, like Flash |
| `grid[x][y]` out of the array | `undefined`: tests on it are false | a guarded accessor (K-Slash `Game.square()` returns `null` = free square) |
| `int(x)` | truncation towards zero | `Std.int(x)` |
| `Std.random(n)`, `Math.random()` | | `Seed.random(n)` / `Seed.rand()` for gameplay, `Seed.randomVfx` / `randVfx` for pure visuals (`determinism`) |
| `static var` changed during a game | the SWF was reloaded for every game | reset in `Game.new` and `Game.destroy` (K-Slash `Hero.SPEED = 5`; Manda: a potion drunk at the end left the snake blue in the next game) |
| `volatile var` | anti-cheat storage of the original | a plain variable |
| `KKApi.const(n)`, `KKApi.val(c)` | protected constants | kept (`common_haxe_avm1.KKApi`) |
| `downcast(x)` | unchecked cast | typed variable / `cast` |
| `{>MovieClip, vx:float, ...}` | a MovieClip with extra fields | a small class holding the clip (`Part`, `Plat`) |
| `gotoAndStop(string(i + 1))` | frame by number given as a string | `gotoAndStop(i + 1)` |
| `Key.addListener({onKeyDown: ...})` | keys handled by events | polled `KeyboardManager` in `update` (the replay records polled keys); a typed sequence that is not a recorded key (K-Slash's NIGHT code) becomes a replay event |
| `mc._width`, `getBounds`, `hitTest` in gameplay | measures the display | exported numbers / masks, never PIXI bounds (`fix-replays-float`) |
| `Timer.tmod` | speed correction for the real frame rate | kept: KadoKadeo runs 32 steps/s with `tmod = 1` |
| `if (a <= 0) X else Y` (Haxe 1 / 2) | the compiler may emit `if (a > 0) Y else X`: with `a` undefined (NaN) the branch flips | port the compiled form, read in the decompiled SWF (Klinker Surprise's `freeTimer`, never set, takes the `else` of the compiled test on the first frame) |
| a library of `WebGamesArchives/libs-haxe2` | not always the version compiled into the game | port the helpers as the SWF compiled them (Klinker Surprise: `Num.sMod` returns the number, not `null`, on a bad modulo; `Col.setPercentColor` has no alpha argument) |
| `Log.print`, `cheat()` | debug code | dropped |

## Flash player (AVM1) rules the code relies on

These come from how Flash 8 plays timelines. The Clip runtime of the recent ports reproduces them; a port that
draws differently from the SWF usually breaks one of them.

- Playheads advance **before** the frame scripts run.
- A nested timeline keeps playing when its parent is stopped.
- A nested clip runs its first-frame script **after** its parent has placed it (K-Slash: spark rings kept their size).
- A `gotoAndPlay` made by the code runs the frame scripts later, in AVM1 order (Pioutch `Clip.runLater`).
- A clip that removes itself (`removeMovieClip` in a frame script) while its parent loops over its children makes
  the parent skip the next child: defer the removal (`Clip.flushRemoved()` at the start of `Game.update`).
- A shape placed at a depth already used keeps the matrix and colour of the previous one (`G.flash_replace = True`
  in `swfrender`).
- A `_parent.removeMovieClip()` on a clip placed by a timeline (not attached by code) does nothing.
- A negative scale (a character turning around) is instant: never interpolate a scale that changes its sign
  (`Clip.noFlipLerp`: otherwise the sprite is squeezed flat for a few frames).
- A clip attached by the code is drawn once at its initial position before its first update: K-Slash monsters
  appeared one frame at (0, 0) of the map; the port hides them for that frame and keeps the position for the code.
- The button under the mouse (rollOver / rollOut) is looked for when the mouse moves or a mouse button changes, not
  when the clips move under a still mouse, nor when a clip gets its handlers under it (checked in Ruffle on Logico: the
  ball that slides under the still pointer glows only once the pointer moves; `logico/Buttons.hx`).
- Colour transforms are rounded to integers (multipliers in percent, offsets in 0..255): `Cs.setPercentColor` of
  K-Slash does the same rounding.

## Flash 9 (AS3) games

A few KadoKado games are AS3 (Haxe 2 `-swf9`: `flash.display.Sprite`, `@:bind` classes; Happy Pti Tank). The rules
differ from AVM1:

- The library links classes to symbols with a `SymbolClass` tag (not `ExportAssets`: `swfdump.py` lists no export).
  A class bound to a symbol builds the symbol's first frame before its constructor body runs; a subclass that is not
  bound gets its parent's symbol (FoeShooter shows Foe's burger). A symbol bound to a `Sprite` class shows frame 1
  only; MovieClips play their timelines on their own, also the ones the code creates.
- Display properties read back what Flash stored: x / y in twips, rotation normalised to ]-180, 180], alpha in 8.8
  fixed point (`alpha -= 1 / 300` loses exactly 1 / 256 per frame). An object moved or coloured by the code is no
  longer moved by its timeline. `removeChild` of an object that is not a child throws (the rest of the frame is
  skipped by the player).
- `getBounds` / `width` transform each picture's rectangle by its whole matrix (not nested boxes);
  `BitmapData.draw(obj)` ignores the object's own transform, alpha, visibility and filters, not its children's.
- A filter on an object (DropShadowFilter of Config.addGroundShadow) renders it into its own bitmap first: a blend
  mode inside it applies over that bitmap (an `add` over nothing draws normally).
- Closures created in a loop capture the loop's variables per iteration (Haxe 2 wraps them in arrays), like Haxe 4.

