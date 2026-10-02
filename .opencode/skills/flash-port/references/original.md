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
  run at 32 (`mt.Timer.wantedFPS`), which is what KadoKadeo does.

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
- Colour transforms are rounded to integers (multipliers in percent, offsets in 0..255): `Cs.setPercentColor` of
  K-Slash does the same rounding.
