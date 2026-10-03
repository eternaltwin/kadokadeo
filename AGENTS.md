# AGENTS.md

## Fast Start (avoid destructive mistakes)

- Use `make` only for first-time setup: it copies `.env.example` -> `.env`, `compose.override.yaml.example` -> `compose.override.yaml`, `eternaltwin/etwin.toml.example` -> `eternaltwin/etwin.toml`, regenerates RSA keys, and runs `migrate:fresh --seed`.
- For normal day-to-day work, use `make docker-start` / `make docker-watch` and avoid re-running `make` unless you want setup/reset behavior.
- `make compile-games` requires running containers (`kadokadeo_app` and `kadokadeo_front`) because it uses `docker exec`.

## Repo Shape

- Main app is Laravel + Vue in this root.
- `resources/hx/` = Haxe game sources; `resources/js/games/*.js` = Haxe-generated JS intermediates (tracked); `public/gamesdata/*` = bundled runtime artifacts + `manifest.json`.
- `eternaltwin/` is a separate local service package used by Docker (`yarn etwin`). Treat it as its own boundary.

## Build and Verification Commands

- Frontend dev: `npm run dev`.
- Frontend lint/format (JS/Vue only): `npm run lint`, `npm run format` (operate on `resources/js`).
- Production build: `npm run build` (installs Haxe libs, compiles all games, bundles games, then Vite build).
- Game bundle only: `make compile-games`.
- Backend tests: `docker exec kadokadeo_app php artisan test` (configured for SQLite in-memory via `phpunit.xml`).
- DB sync/reset in Docker context: `make sync-database`, `make reset-database`.

## Game Pipeline Gotchas

- Do not hand-edit generated files in `resources/js/games/*.js` or `public/gamesdata/*.js`; edit Haxe in `resources/hx/games/*` then rebuild.
- Add/remove a game in both `compile.hxml` and `compile-dev.hxml`.
- `resources/js/games/build-games.mjs` bundles **every** non-`tmp*.js` file in `resources/js/games`; stale JS files are still shipped unless removed.
- `build-games.mjs` also archives the previous version of every bundle that changed in `storage/app/game-builds` (replays are played by the version they were recorded with, see `.opencode/skills/replay-system/SKILL.md`): never delete that folder; `GAME_BUILDS=off` skips it.
- Runtime game loading depends on DB game name -> `game_key` mapping (`App\Models\Game::getGameKeyAttribute`), so filenames must match sanitized lowercase game names (e.g. `Opalus 2` -> `opalus2.js`).

## Backend/API Conventions That Matter

- API auth is enforced per-controller with `HasMiddleware`/`Middleware` (not one global auth group in `routes/api.php`).
- Run submission crypto depends on RSA key files from `config/kado.php` (`KADO_RSA_PRIVATE_KEY_PATH`, `KADO_RSA_PUBLIC_KEY_PATH`).
- Public RSA key is injected into `window.Kado.public_key` in `resources/views/layouts/default.blade.php`; game clients use it to encrypt run payloads.
- Admin panel (Filament, `/admin`) UI must be in **French**: every user-facing string in `app/Filament/`, `app/Livewire/` admin widgets and `resources/views/filament/` (labels, headings, notifications, options, tabs). Always set an explicit French `->label()` on fields/columns (Filament otherwise derives English labels from column names) and `$modelLabel`/`$pluralModelLabel` on resources. Code identifiers stay in English.
- Scheduled commands are defined in `routes/console.php` and executed by container cron (`docker/app/conf/crontab` runs `artisan schedule:run` every minute).

## Existing Agent Guidance

- Keep `CLAUDE.md` as the companion high-level map; this file is the short, high-signal checklist.
- For Flash-to-Haxe porting or replay/scale/determinism tasks, check `.opencode/skills/*/SKILL.md` before changing game code.
- Porting a KadoKado Flash game (or redoing / fixing a port): start with `.opencode/skills/flash-port/SKILL.md` (method, tools in `scripts/`, K-Slash walkthrough). The `scale` skill is legacy: new ports scale the root container x2.
