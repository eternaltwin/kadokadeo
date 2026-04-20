# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KadoKadéo is a competitive gaming platform on the EternalTwin ecosystem. Users play daily games (ported from Flash via Haxe), earn points, and compete in weekly rankings. The stack combines Laravel (backend API), Vue.js (SPA frontend), and Haxe-compiled games rendered with PixiJS.

## Development Commands

### Full Setup
```bash
make          # Install everything and start containers (first-time setup)
make build    # Rebuild Docker images
```

### Daily Development
```bash
make docker-start    # Start containers in background
make docker-watch    # Start containers with logs visible
make docker-stop     # Stop containers
make bash-app        # SSH into app container
```

### Frontend
```bash
npm run dev          # Vite dev server with HMR
npm run build        # Full build (Haxe compile + bundle + Vite)
npm run lint         # ESLint fix
npm run format       # Prettier format
```

### Backend (inside container or with Docker exec)
```bash
composer dev         # Concurrent servers: Laravel + queue + logs + Vite
composer test        # Run PHPUnit tests
php artisan test     # Alternative test runner
composer db:sync     # Run pending migrations
make sync-database   # Same via Makefile
make reset-database  # Reset PostgreSQL database
```

### Games (Haxe)
```bash
haxe compile-dev.hxml    # Compile games (development, with debug)
haxe compile.hxml        # Compile games (production)
make compile-games        # Compile and bundle all games
npm run games:bundle      # Bundle compiled games only (via esbuild)
```

## Architecture

### Backend (`app/`)
Laravel 12 API-first architecture with service layer:
- **Controllers** (`app/Http/Controllers/Api/`): Thin — delegate to services
- **Services** (`app/Services/`): Business logic — `GameService`, `RunService`, `ScoreService`, `PeriodService`
- **Models** (`app/Models/`): Eloquent — `User`, `Game`, `Run`, `Period`, `DailyGame`, `UserStar`, `UserPoint`
- **Filament** (`app/Filament/`): Admin panel (Filament 4.0)

Authentication is Laravel Sanctum tokens issued after EternalTwin OAuth callback.

Game score submission uses RSA encryption: `RunService` signs scores with a private key (`KADO_RSA_PRIVATE_KEY_PATH`). Keys live in `storage/app/private/`.

Rankings are scoped to `Period` records (weekly rotation). The `kado:prepare-new-period` and `kado:reset-daily-games` Artisan commands run on cron.

### Frontend (`resources/js/`)
Vue 3 SPA with Pinia state management and Vue Router:
- **`pages/`**: Route-level page components
- **`games/`**: Game UI and integration with Haxe JS
- **`stores/`**: Pinia stores for auth, games, user state
- **`composables/`**: Reusable logic via Composition API
- **`middlewares/`**: Vue Router guards (auth checks)
- **`pixi-tween/`**: Custom PixiJS tweening library

### Games (`resources/hx/`)
Games are written in Haxe, compiled to individual JS files, then bundled:
1. Each game lives in `resources/hx/games/[name]/` with a `Game.hx` implementing `kado.GameInterface`
2. `compile.hxml` / `compile-dev.hxml` list all games for the Haxe compiler
3. Compiled JS goes to an intermediate directory, then `build-games.mjs` bundles them
4. Final output: `public/gamesdata/[name].js` + `manifest.json` with content hashes
5. Spritesheets are managed with TexturePacker, output to `public/assets/img/content/[name]/`

The `NEW_GEN_SCALE` convention upscales old 300×300 game coordinates to 900×900.

### Key API Routes (`routes/api.php`)
- `POST /oauth/callback` — EternalTwin OAuth login → Sanctum token
- `GET /daily/game` — Today's daily game
- `POST /runs/games/{game}` — Start a run
- `POST /runs/{run}/finish` — Submit score
- `GET /games/{game}/scores` — Rankings

### Data Flow: Game Session
1. Frontend fetches daily game via API
2. Loads compiled Haxe JS (`public/gamesdata/[name].js`)
3. PixiJS renders game in canvas
4. On finish: frontend `POST /runs/{run}/finish` with score
5. `RunService` validates, RSA-signs, persists score
6. `ScoreService` updates stars and period rankings

## Testing

Tests use SQLite in-memory (configured in `phpunit.xml`). Feature tests cover API endpoints; unit tests cover services.

```bash
composer test                              # All tests
php artisan test --filter TestClassName    # Single test class
php artisan test tests/Feature/RunTest.php # Single file
```

## Environment

Key `.env` variables beyond standard Laravel:
- `KADO_GAMES_PER_DAY` — Max games per user per day (default: 100)
- `KADO_RUNS_MAX_CONCURRENCY` — Max concurrent runs per user (default: 5)
- `KADO_RSA_PRIVATE_KEY_PATH` / `KADO_RSA_PUBLIC_KEY_PATH` — RSA key paths for score signing

## Adding a New Game

1. Create `resources/hx/games/[name]/` with `Game.hx` implementing `kado.GameInterface` and an `import.hx`
2. Add game entries to `compile.hxml` and `compile-dev.hxml`
3. Add spritesheet assets to `public/assets/img/content/[name]/` (use TexturePacker `.tps` project)
4. Run `make compile-games` to compile and bundle
5. Add the game record to the database (via Filament admin or seeder)

See `.opencode/skills/mt-to-haxe/SKILL.md` for the Flash-to-Haxe porting workflow.
