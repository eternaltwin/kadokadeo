# Testing a port

Everything is tested in a headless browser driven through the DevTools protocol, with **real** keyboard, mouse
and touch events: they go through the same path as a player's (KadoKadeo's input managers, the replay recorder),
which is the only way to catch control and replay bugs. Paths below are relative to
`.opencode/skills/flash-port/scripts/`.

## Contents
- Harness: build, server, test page
- cdp.mjs
- Bot + replay (the main test)
- Test modes
- Seeking
- Touch
- Frame by frame
- Performance and smoothness
- Shared code: replays of other games
- When a replay diverges
- Test pitfalls

## Harness: build, server, test page

```sh
sh harness/build.sh <game>                # debug build -> $KKP_WORK/build/<game>.js (BUILD_OK)
python3 harness/server.py [port] &        # default 8765; serves www/, the builds, modes/, public/ of the repository
open "http://127.0.0.1:8765/game.html?game=<game>&cls=Game<Name>&seed=123"
```

- After `build.sh`, reloading the page is enough (the server sends `no-store`).
- Page parameters: `seed` (the **debug build always plays seed 123 live**, `createDebugContext`: pass `seed=123`
  to replays too), `replay=<data>` (watch a replay), `test=<mode>` (below), `js=<bundle>` (another build).
- At the end of a game KadoKadeo logs `Replay data: <data>` (debug builds), collected by the page in
  `window.__logs`; the game's own end state is in `window.__over` (see `code.md`).
- PixiJS 6.0.2 and pixi-filters 5.0.0 (the versions of the site) are downloaded once by the server into
  `$KKP_WORK/vendor`: tests then run offline.

## cdp.mjs

```js
import { launch } from '../../harness/cdp.mjs'          // from scripts/examples/<game>/
import { HOST, gameDir } from '../../harness/paths.mjs'
const b = await launch(9510)                            // DevTools port: one per script running in parallel
await b.goto(HOST + '/game.html?game=kslash&cls=GameKSlash&seed=123')
await b.waitFor('!!(window.kk && kk.game && kk.game.hero)', 60000)
await b.send('Input.dispatchKeyEvent', { type: 'keyDown', windowsVirtualKeyCode: 37, nativeVirtualKeyCode: 37, key: 'ArrowLeft', code: 'ArrowLeft' })
const state = await b.eval('JSON.stringify(window.__over)')
await b.screenshot(gameDir('kslash', 'shots') + '/a.png', { x: 8, y: 8, width: 600, height: 640 })   // the canvas is at (8, 8)
console.log(b.consoleLines.filter((l) => /EXCEPTION|CRASH/.test(l)))
await b.close()
```

- `GPU=1` uses the real GPU (otherwise SwiftShader, a software renderer: right for logic, wrong for performance).
- From test JS, Haxe properties are read through their getters (`mc.get__x()`), and
  `obj.constructor.prototype` is `Object.prototype` (use `Object.getPrototypeOf(obj)`).
- `kk` is the `KadoKadeoManager`: `kk.game` (the game instance), `kk.seekReplay(f)`, `kk.setReplaySpeed(s)`
  (replays only), `kk.updatePhysics(1000 / 32)` (one step by hand), `kk.ff.onTick` (the fixed-rate loop).

## Bot + replay (the main test)

Model: `examples/kslash/k3.mjs`. For a new game, write `examples/<game>/<x>3.mjs`:

1. a bot reads the game state (`b.eval`) and plays like a human with real events: goes for bonuses, avoids
   enemies, uses **every** control (including the alias keys ZQSD / WASD / Enter), until `window.__over`;
2. it saves `Replay data:` + `__over` (`$KKP_WORK/<game>/replays/`), reloads the page with `&replay=...`, speeds
   the replay up (`kk.setReplaySpeed(8)`), waits for `__over` and compares: **`MATCH`** expected;
3. several bot seeds (`node k3.mjs 1`, `2`, `3`), and the coverage mode
   (`EXTRA='&test=ks&dif=6000&ids=4,5,6,7,8,9,10&inv=1&frames=1500' node k3.mjs 2`).

A live game cannot be sped up (`setReplaySpeed` only applies to replays): bots play in real time, so run several
in parallel with different `PORT` values. Results of the K-Slash bots:

```
live   {"frame":538,"score":810,"hx":0,"hy":24,"dif":805.5,"mons":4,"stars":28,"stats":"{...}","night":false} ...
replay {"frame":538,"score":810,"hx":0,"hy":24,"dif":805.5,"mons":4,"stars":28,"stats":"{...}","night":false} MATCH
```

## Test modes

A random game rarely reaches the late game, every bonus or every enemy. A test mode patches the game from the
page to get there: `harness/modes/<game>.js` adds `TEST_MODES.<name> = (proto, query) => {...}`, which wraps
`proto.update` (see `modes/kslash.js`: difficulty from the start, a bonus given on the hero every N frames,
immortal hero, game over at frame N). Rule: **it must do exactly the same thing in the live game and in its
replay**: only the frame counter and the URL may decide, never time or randomness. `test=generic&frames=N`
(built in, any game) only forces the game over at frame N.

## Seeking

`node harness/s3.mjs <game> Game<Name> <devtools port> [frames]`: a random game with `test=generic`, then in its
replay a seek to 60 %, back to 20 %, 60 % again, normal playback vs seek to the same frame (score + hash of the
whole display tree), end of the replay. Expected:
`"again60":"SAME","playedVsSeek":"SAME","endMatch":"MATCH"`. `test=generic` ends with `kk.gameOver({})`: if the
game still adds points during its own end animation, `endMatch` can differ without a bug; end the game through the
game's code instead (a test mode).

Game-specific version on a real bot game: `examples/kslash/ks1.mjs <replay file of k3.mjs>`.

## Touch

Model: `examples/kslash/ktouch.mjs`. `Emulation.setTouchEmulationEnabled` then `Input.dispatchTouchEvent`
(`touchStart` / `touchEnd`, several fingers): check that each button and joystick direction acts (shot fired,
hero moved), then that the replay of the touch game, watched on desktop, matches. A `touchMove` that drops a
finger sends no `pointerup`: use separate `touchStart` / `touchEnd` gestures.

## Frame by frame

`node harness/step.mjs <game> Game<Name> <out prefix> '<condition js>' <count> [extra url]`: stops the loop
(`kk.ff.onTick = () => {}`), steps the physics by hand until the condition, then one screenshot per step (`STEP`
frames per shot, `KEYS` js before each step, `PRESS=keyCode,key` once). To check an animation, an explosion, a
clip change. Look at the pictures.

## Performance and smoothness

With `GPU=1`:
- `harness/shaders.mjs <game> <Class> [ms]`: shader programs compiled and big textures uploaded during the game
  (each blocks a frame the first time). Expected: 0 shaders (warm them at start).
- `harness/hitchprof.mjs <game> <Class> [ms]`: CPU profile of the frames longer than `LIMIT` ms.
- `harness/hitch.mjs`: physics / render / texture upload time per long frame.
- `harness/stutter.mjs <game> <Class> '<hero sprite js>' [ms]`: shown time and hero position on every picture
  (jerks, interpolation jumps). K-Slash: `kk.game.hero.root`, 0 jerks.
- a heavy scene of the game: `examples/kslash/kperf.mjs` (cost of a physics step, real frame rate). K-Slash:
  0.12 ms per step, 60 frames/s with 12 monsters and the super hero's afterimages.

## Shared code: replays of other games

When `resources/hx/lib` changes, replays recorded before the change must still play the same:

```sh
# on the branch BEFORE the change (build each game with build.sh first)
node harness/rc.mjs record $KKP_WORK/rc_base.jsonl 9341 kslash:GameKSlash manda:GameManda minirace:GameMiniRace ...
# after the change (rebuild the same games)
node harness/rc.mjs check $KKP_WORK/rc_base.jsonl 9341      # "state 60% SAME | end MATCH" for every game
```
`tools/replaystat.py <replay file>` decodes a replay (versions 1 to 3) and shows the size of each section.

## When a replay diverges

1. Find the first frame that differs: record a per-frame trace in a test mode (`window.__trace.push(...)` of the
   positions / random calls in live and in replay) and compare.
2. Usual causes: gameplay reading the display (interpolated or PIXI values), visual effects consuming gameplay
   random, unrounded trigonometry at a threshold, a static not reset, an input read from an event instead of
   polling, a replay event applied at a different frame in live and replay. Then the `fix-replays-float` skill.

## Test pitfalls

- Never click the canvas to "start" a replay: a click pauses it.
- Headless Chrome on macOS hides the page at the first input event unless it is brought to the front: `cdp.mjs`
  does it in `goto`. A test whose game seems frozen (frames stop advancing) with a custom navigation must do the
  same (`Page.bringToFront`).
- One DevTools port per running script; kill browsers left by an interrupted script (`pkill -f kk-cdp-profile-<port>`:
  a bare `pkill -f kk-cdp-profile` also closes the browsers of the other sessions).
  The browser profile is per port (`kk-cdp-profile-<port>`): two sessions using the same `PORT` share one browser
  (the second script drives the first one's page, `CDP timeout` errors on both sides). Several sessions at the same
  time: give each its own range of ports, and check a port is free (`curl 127.0.0.1:<port>/json`) before using it.
- Debug build for the tests (`__over`, seed 123), production build only to check it compiles.
- Look at the screenshots before claiming a display is right.
