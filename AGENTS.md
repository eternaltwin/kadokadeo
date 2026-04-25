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
- Runtime game loading depends on DB game name -> `game_key` mapping (`App\Models\Game::getGameKeyAttribute`), so filenames must match sanitized lowercase game names (e.g. `Opalus 2` -> `opalus2.js`).

## Backend/API Conventions That Matter

- API auth is enforced per-controller with `HasMiddleware`/`Middleware` (not one global auth group in `routes/api.php`).
- Run submission crypto depends on RSA key files from `config/kado.php` (`KADO_RSA_PRIVATE_KEY_PATH`, `KADO_RSA_PUBLIC_KEY_PATH`).
- Public RSA key is injected into `window.Kado.public_key` in `resources/views/layouts/default.blade.php`; game clients use it to encrypt run payloads.
- Scheduled commands are defined in `routes/console.php` and executed by container cron (`docker/app/conf/crontab` runs `artisan schedule:run` every minute).

## Existing Agent Guidance

- Keep `CLAUDE.md` as the companion high-level map; this file is the short, high-signal checklist.
- For Flash-to-Haxe porting or replay/scale/determinism tasks, check `.opencode/skills/*/SKILL.md` before changing game code.
