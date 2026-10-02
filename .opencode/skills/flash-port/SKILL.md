---
name: flash-port
description: Port a KadoKado Flash game (MTypes / AS2 sources and SWF files from motion-twin/WebGamesArchives) to KadoKadeo (Haxe 4 + PixiJS 6, 600x600, 32 frames/s, deterministic replays) - read the original, convert the code, extract the graphics from the SWF, test replays / seeking / touch / performance, register the game. Use it for a new port, for redoing an old port from the original sources, and for port bugs (replay that diverges, misplaced or flickering sprite, stutter, frame hitch, NaN).
---

# Porting a KadoKado Flash game to KadoKadeo

**KadoKado** was Motion Twin's site of 300x300 Flash mini-games (2006-2010). Their sources are public in
`motion-twin/WebGamesArchives`, folder `KadoKado/Games/<Name>`: game code in MTypes (`.mt`, a Haxe ancestor) or
ActionScript 2, graphics in SWF files. **KadoKadeo** (this repository) replays them in the browser: each game is
Haxe 4 compiled to JavaScript, drawn with PixiJS 6 at x2 (600x600), updated 32 times per second, and every game
is recorded as a replay (seed + inputs) that must give back exactly the same game.

A port is finished when it **is the original game**: same rules, speeds, randomness, order of the calls and even
the same quirks, rewritten from the original code, with graphics extracted from the original SWF (nothing
redrawn), and replays that reproduce every game exactly. Players know these games by heart: a different speed or
a sprite 2 px off is noticed.

K-Slash (`resources/hx/games/kslash`) is the reference port; [references/kslash-walkthrough.md](references/kslash-walkthrough.md)
follows it from the archive folder to the committed game.

## Related skills

| Skill | Use it for | Notes |
|---|---|---|
| `mt-to-haxe` | MTypes syntax -> Haxe (types, semicolons, switch, imports) | **Except** loops over a list that can change during the loop: `while (i < list.length)`, never `for (i in 0...list.length)` (see [references/original.md](references/original.md)) |
| `mt-to-kadokadeo` | `import.hx`, `Game` class, `KKApi`, `KeyboardManager` | |
| `determinism` | gameplay random on `Seed.random`, visual random on `Seed.randomVfx` | |
| `replay-system` | `replay.init`, polled inputs, replay events | |
| `fix-replays-float` | finding why a replay diverges | |
| `scale` | **legacy**: multiplies every coordinate by `KadoKadeoManager.S()` / `I()` | Do not use for a new port: scale the root container x2 instead ([references/code.md](references/code.md)) |

## Rules

- **Read the original before writing.** Port file by file and function by function: one Haxe file per original
  file, same class, field and method names, same order of the calls, same display depths. Someone must be able to
  read the original and the port side by side.
- **Do not improve the game.** Keep its quirks (a kunai updated twice per frame, a sprite drawn one frame at the
  origin...) and write a comment (in English) on every deliberate difference and why.
- When a behaviour is surprising, the answer is in the original code or in the rules of the Flash 8 player (AVM1),
  not in a guess: [references/original.md](references/original.md), [references/pitfalls.md](references/pitfalls.md).
  When the MTypes meaning is unclear, decompile the released SWF and read the compiled code.
- **Every picture comes from the SWF** (rendered at x2 by the tools of `scripts/`), never redrawn or upscaled.
- **Never edit generated files**: `Data.hx` (written by the game's `<game>_data.py`), `resources/js/games/*.js`,
  `public/gamesdata/*`. Fix the generator and rebuild.
- **Shared code** (`resources/hx/lib`) changes only when there is no other way, and then for every game: check
  that other games still compile and that recorded replays still play the same ([references/testing.md](references/testing.md)).
- **Done means verified**: the checklist below passes, and the user has seen screenshots of the game next to the
  original.

## Where things are

| Path | What |
|---|---|
| `resources/hx/games/<game>/` | the port (package = game key: lowercase name without spaces or punctuation, `Mini-Race` -> `minirace`) |
| `public/assets/img/content/<game>/` | sprite sheets `<game>-N.json/png`, `src/` (single images), `<game>.tps` (TexturePacker project) |
| `public/assets/img/gfx/artwork/<game>.jpg` | 600x600 start screen picture (required) |
| `compile.hxml`, `compile-dev.hxml`, `database/seeders/GameSeeder.php` | registration of the game |
| `.opencode/skills/flash-port/scripts/tools/` | SWF -> images and timelines -> sprite sheets (Python) |
| `.opencode/skills/flash-port/scripts/harness/` | test harness: build, server, headless browser driver, generic tests (Node) |
| `.opencode/skills/flash-port/scripts/examples/kslash/` | everything K-Slash needed: asset scripts, test bots, test mode, comparison pages |
| `$KKP_WORK/<game>/` (default `~/kadokadeo-port/<game>`) | work folder of a port, outside the repository: SWF copies, FFDec exports, `out/`, `check/`, replays |

## Workflow

1. **Set up** once: [references/setup.md](references/setup.md) (Haxe libs, Python, FFDec, Node 22, Chrome).
2. **Inventory the original**: [references/original.md](references/original.md). Read every source file, list the
   symbols, labels, named children and frame scripts the code uses, check that the archive SWF is the released
   one. Export the SWF files: `sh scripts/tools/prepare_game.sh <archive>/KadoKado/Games/<Name> <game>`.
3. **Port the code**: [references/code.md](references/code.md). Structure, root scaled x2, inputs, randomness,
   timing, game over, then registration in the repository.
4. **Extract the graphics**: [references/graphics.md](references/graphics.md). Choose the pipeline (Clip
   timelines or simple renders), write `<game>_assets.py` + `<game>_data.py` + `rebuild_assets.sh` from the K-Slash
   example, pack the sheet, compose the start screen.
5. **Read [references/pitfalls.md](references/pitfalls.md)** before writing the display code, and again whenever a
   bug looks impossible (NaN, stutter, shader hitch, sprite that jumps, replay that diverges).
6. **Test**: [references/testing.md](references/testing.md). A bot plays real games with real key / mouse / touch
   events and each replay must `MATCH`; seeking, touch, performance, SWF-vs-game comparison pages.
7. **Commit** on the game branch (`game/<game>`): message `✨ (<game>) ...` like the history, body listing what
   was ported, what differs and why. No push unless asked.

To see how a problem was already solved in another port: [references/ported-games.md](references/ported-games.md).

## Done checklist

- [ ] Debug and production builds compile without new warnings (`sh scripts/harness/build.sh <game>` and
      `sh scripts/harness/build.sh <game> prod`), and `make compile-games` passes in Docker.
- [ ] Several bot games with real inputs: each replay gives the same end state (`MATCH`: score, frame, positions,
      stats), including a coverage mode that triggers every bonus / enemy / ending of the game.
- [ ] Seeking in a replay: `s3.mjs` gives `"again60":"SAME","playedVsSeek":"SAME","endMatch":"MATCH"`.
- [ ] Touch controls (mobile emulation) are playable, and the replay of a touch game watched on desktop matches.
- [ ] With the real GPU (`GPU=1`): no shader compiled during the game, no long frame, no stutter.
- [ ] Every animation drawn by the game compared with the same clip rendered from the SWF; the user has seen the
      comparison pages and in-game screenshots.
- [ ] No gameplay value reads the display (interpolated positions, PIXI bounds, rendered pixels).
- [ ] `compile.hxml`, `compile-dev.hxml`, `GameSeeder.php`, sheets + `src/` + `.tps`, artwork: all committed;
      no hand-edited generated file.
