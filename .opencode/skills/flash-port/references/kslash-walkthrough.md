# Worked example: K-Slash

K-Slash (`kslash`, exposed `GameKSlash`) was first ported with the older method: values multiplied by
`KadoKadeoManager.S()` / `I()`, some of them tuned by feel (`weight = KadoKadeoManager.S(0.7) + 0.2`), a kunai
that had lost its double update, and graphics in 2 sheets of 4.8 MB. In October 2026 it was redone from the
original sources, following
this skill (commits `K-Slash: new port from the original sources` and `K-Slash: no paper effect when turning
around`). This file follows that port step by step; every script mentioned is in
`.opencode/skills/flash-port/scripts/`.

## Contents
1. Inventory
2. Work folder
3. Code, file by file
4. Deliberate differences
5. Graphics
6. Tests
7. Commit

## 1. Inventory

`WebGamesArchives/KadoKado/Games/kslash/`: 14 MTypes files in `src/` (2576 lines), `swf/gfx.swf` (characters,
bonuses, effects, interface: 316 shapes, 2 fonts) and `swf/decor.swf` (backgrounds: 8 bitmaps).

| Original | Port | Notes |
|---|---|---|
| `Manager.mt` | (none) | Flash entry point: KadoKadeo creates `Game` |
| `Game.mt` | `Game.hx` | + replay setup, touch controls, test hooks (`__over`, `debugShow`), `warmShaders` |
| `Cs.mt` | `Cs.hx` | + `q()` (rounding of trigonometry), `setPercentColor` with a `ColorMatrixFilter` |
| `Ent.mt`, `Hero.mt`, `Monster.mt`, `Runner.mt`, `Soldier.mt`, `Tanker.mt`, `Flyer.mt` | same names | entities |
| `Shoot.mt`, `Kunai.mt`, `Star.mt`, `Bonus.mt` | same names | shots, bonuses |
| `{>MovieClip, vx, vy, ...}` in `Game.mt` | `Part.hx` | particles: a class holding the clip |
| (the SWF) | `Data.hx` | generated: timelines, decor matrices, measured widths, text layouts |
| (Flash player) | `Clip.hx`, `Tex.hx`, `Digits.hx`, `PlatGfx.hx` | timeline player, textures of this game's sheet, numbers in the SWF fonts, platforms without a mask |

What the code uses from the SWF (from `Game.mt`, `Hero.mt`... and `dump_gfx.txt`): the symbols `mcHero`,
`mcMonster`, `mcTanker`, `mcFlyer`, `mcShade`, `mcKunai`, `mcNinjaShot`, `bonus`, `mcIcon`, `mcPlat`, `inter`,
`mcScore`, the particles `partLight`, `partSmoke`, `partDust`, `partCircle`, `partSpark`; the labels the hero and
monsters play (`walk`, `run`, `fly_down`, `death`...); the named children the code drives (`mc.mask`,
`mc.corner` of the platforms, `inter.fieldStar`, the soldier's `b1`, `b3`..`b5`); and the decor sprites `bg`,
`bgFront`, `bgBack`, whose `_width` the code reads.

## 2. Work folder

```sh
sh scripts/tools/prepare_game.sh ~/code/WebGamesArchives/KadoKado/Games/kslash kslash gfx decor
```
`$KKP_WORK/kslash/` then holds the SWF copies, `shp4_gfx/`, `shp1_gfx/`, `svg_decor/`, `img_decor/`,
`fonts_gfx/292_Arial Black.ttf`, `fonts_gfx/403_Impact.ttf`, `as_gfx/` and `dump_*.txt`.

## 3. Code, file by file

**Game constructor.** The original, line by line, plus what KadoKadeo needs before it:

```haxe
// original: function new(mc) { Cs.game = this; dm = new DepthManager(mc); root = mc; bg = downcast(dm.attach("bg",DP_BG)) ...
public function new(root:ASprite, ?isReplay:Bool = false) {
    KadoKadeoManager.kkm.replay.init({recordedKeys: replayKeys /* LEFT RIGHT UP DOWN SPACE CONTROL */,
        recordInputs: true, recordEvents: true /* the NIGHT code */, ...});
    Cs.game = this;
    Hero.SPEED = 5;                                          // a static the game changes: reset
    Clip.flushRemoved();
    this.root = root.createEmptyMovieClip("scene", 0);
    this.root._xscale = this.root._yscale = 100 * Clip.K;    // 300x300 Flash pixels drawn x2
    dm = new DepthManager(this.root);
    bg = decorPlan(Data.DECOR_BG, 1, DP_BG);                 // dm.attach("bg") + bg.stop()
    inter = Clip.attach(dm, "inter", DP_INTER);
    ...
        var c = (widths[i] - 300) / 300;                     // was (m._width - 300) / 300: measured in the SWF
    ...
    if (Seed.randVfx() * 500 < 1) setNight();                // was Math.random(): only colours change -> visual seed
    warmShaders();
}
```

**Main loop.** `main()` becomes `update(delta)`. The loops stay index loops, because an entity removed during
its update makes the next one wait a frame in the original:

```haxe
// original: for( var i=0; i<mList.length; i++ ){ mList[i].update(); }
var i = 0;
while (i < mList.length) {
    mList[i].update();
    i++;
}
```

**Kunai updated twice per frame.** `Shoot.new` pushes the shot in `sList` and `Kunai.new` pushes it again: the
kunai moves twice per frame in the Flash game, and the first port had lost it. Kept, with a comment:

```haxe
public function new(mc:Clip) {
    super(mc);
    // (a second time: the kunai is updated twice per frame, like in the original)
    Cs.game.sList.push(this);
}
```

**Secret code.** The original listened to key events (`Key.addListener`) and compared the codes with N-I-G-H-T.
The letters are not recorded keys, so live play detects the sequence from the frame's key changes and records a
replay event; both live and replay apply it when the event comes back:

```haxe
// update(), first lines
for (e in KadoKadeoManager.kkm.replay.consumeEvents())
    if (e != null && e.k == EV_NIGHT) setNight();
if (nightTyped) { nightTyped = false; setNight(); }          // live: the frame after the event, like the replay
if (!isReplay)
    for (c in KeyboardManager.getFrameKeyChanges())
        if (c.isDown) pushKey(c.keyCode);                    // records {k: EV_NIGHT} when the code is complete
```

**Grid out of bounds.** `grid[x][y]` outside the array was `undefined` in Flash (a free square):

```haxe
inline function square(x:Int, y:Int):Square
    return (x >= 0 && x < XMAX && y >= 0 && y < YMAX) ? grid[x][y] : null;
```

**Entities.** `Ent.hx` keeps the grid physics of `Ent.mt` (`x`, `y` square + `dx`, `dy` offset, `recal()`). A
clip attached by the code was shown one picture at (0, 0) of the map before its first update: hidden until then,
and its first placement is not interpolated (`snap`). Fields the original sets to `null` and tests are
`Null<Float>` (`friction`, `woodTimer`, `sTimer`).

**Randomness and trigonometry.** Every `Std.random` / `Math.random` of the gameplay is `Seed.random` /
`Seed.rand`; particles, the random night and the log's rotation use the VFX seed. Every value computed with
`cos`, `sin`, `atan2` that enters the game state is rounded: `s.vx = Cs.q(Math.cos(a + da) * speed)`.

**Inputs.** `Key.isDown(Key.LEFT)` -> `KeyboardManager.isDown(KeyboardManager.LEFT)`, polled in `update`.
`KEY_ALIASES = ALIASES_MOVE.concat(ALIASES_ENTER_SPACE)`: ZQSD / WASD and Enter. Touch: a floating joystick
(left / right run, up jump, down drop through) turned into arrow keys in `pollTouchControls`, plus a jump button
(UP) and a shuriken button (SPACE).

**End of the game.** `Hero` calls `Cs.game.gameOver()` when the dead hero bounces at the bottom;
`Game.gameOver` stores `__over` (debug) and calls `kkm.gameOver(stats)` once; `addScore` ignores points after it.

## 4. Deliberate differences

Each is commented in the code:
- the monster hidden for its first frame (Flash drew it at the origin of the map);
- `dist<optList[OPT_KATANA]?72:48` in `Hero.shoot` read as the reach of the slash (72 with the katana, 48 without),
  as the commented-out `BLADE_SIZE` of the source says;
- no points after the game over;
- a flip (negative scale) is never interpolated (Flash flips instantly).

Kept on purpose: the kunai updated twice, the index loops that delay the element after a removed one, the random
night 1 time in 500.

## 5. Graphics

`examples/kslash/kslash_assets.py`, in order:

1. **Characters, flattened per frame** (`strategy='flat'`) on the frames the code can reach only
   (`HERO_FRAMES = rng((1, 26), (29, 36), ...)`, from the labels and their `stop`s). Nested animations that play on
   their own stay separate clips: scarf, headband letter (never mirrored: custom script `kflip`), ball, running
   smoke, slash (`code=('blade',)`), wings, sparkles.
2. **One soldier clip for the 3 levels**: `code=('b1', 'b3', 'b4', 'b5')`; the code chooses the skin and the
   spikes like `Soldier.setLevel` did; the death pieces take the skin frame (`['x', 'skin']`).
3. **One explosion sequence** for every monster: `Eg.families = [FAMILY]`, white, tinted at run time.
4. **Afterimages** of the super hero (`mcShade`): white silhouettes of every hero frame (`cx=C.WHITE`), coloured by
   a table computed from `mcShade`'s colour tween (one flat colour per frame).
5. **Gems**: a colour transform no tint can reproduce: one baked variant per gem colour.
6. **Platforms and decor**: bitmaps at native resolution (`shp1_*`, `res=0.5`), the decor placed with the
   matrices of its bitmap fills (read in `svg_decor/`), the platform strip drawn as a piece of texture instead of
   a mask (`PlatGfx.hx`); the `_width` of each decor frame measured for the parallax.
7. **Digits** of the star counter (Arial Black) and score popups (Impact) from the embedded fonts, with the Flash
   text-field layout (`Data.DIGIT_STAR`, `Data.DIGIT_SCORE`, `Digits.hx`).
8. Unused clips removed, then `clips.json`, `pivots.json`, `meta.json`.

`kslash_data.py` writes `Data.hx`; `rebuild_assets.sh` packs one sheet (`PACK_MAX=2040`) and the `.tps`, and
copies everything into `public/assets/img/content/kslash/`. Result: 52 clips, 66 animations, 634 frames, one
2040 x 1891 sheet of 2.6 MB (the previous port: 4.8 MB in two sheets). Running it again gives the committed
files back.

Runtime fixes made in `kslash/Clip.hx` for this game (now part of the model to copy): first-frame scripts of
nested clips run after their placement (the spark rings kept their size), self-removal deferred to
`Clip.flushRemoved()` at the start of `update`, `noFlipLerp`.

Comparison: `pages.json` lists the hero's animations, afterimages, soldiers of the 3 levels and their deaths,
tanker, flyer, the 10 bonuses, icons, shots, particles, interface, platforms; `ref.py` (SWF) and `ncheck.mjs`
(game) render them, `cmp_pages.py` puts them side by side: identical except anti-aliasing and random sparkles.

## 6. Tests

```sh
cd .opencode/skills/flash-port/scripts
sh harness/build.sh kslash && sh harness/build.sh kslash prod && sh harness/build.sh kslash
python3 harness/server.py &
node harness/s3.mjs kslash GameKSlash 9333 600        # again60 SAME, playedVsSeek SAME, endMatch MATCH
node examples/kslash/k3.mjs 1                         # bot game + replay: MATCH
EXTRA='&test=ks&dif=6000&ids=4,5,6,7,8,9,10&inv=1&frames=1500' PORT=9651 node examples/kslash/k3.mjs 2   # coverage: MATCH
node examples/kslash/ks1.mjs $KKP_WORK/kslash/replays/ks_replay_1.txt   # seeks in a bot replay: SAME, end MATCH
node examples/kslash/ktouch.mjs                       # joystick + buttons act, touch replay MATCH
GPU=1 node harness/shaders.mjs kslash GameKSlash 8000 # 0 shaders compiled during the game
GPU=1 node examples/kslash/kperf.mjs                  # 0.12 ms per physics step, 60 frames/s on a heavy scene
node harness/stutter.mjs kslash GameKSlash 'kk.game.hero.root' 5000   # 0 jerks
```
The original delivery also played the NIGHT code live and in replay, 3 full games and 3 coverage games up to 4000
frames (77 flyers, 7 tankers, every bonus), and checked the rewind after forward and backward jumps.

## 7. Commit

One commit for the port (code, `Data.hx`, sheet, `src/`, `.tps`; the game was already registered in
`compile.hxml` and `GameSeeder.php`), its message listing what was ported, what is kept on purpose, how the
graphics are built and the size gained; a second small commit for the flip fix found while testing.
