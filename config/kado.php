<?php

return [
    'games_per_day' => env('KADO_GAMES_PER_DAY', 100), // -1 for unlimited

    // a replay of a run outside the daily game must have its draws stirred by the frames and the inputs
    // (App\Support\ReplayHeader::FLAG_RNG_STIR), otherwise the run is flagged as cheated. To turn on once the pages
    // opened before the deployment of the games with the stir are gone (a day or two).
    'require_rng_stir' => env('KADO_REQUIRE_RNG_STIR', false),

    // the replays of the runs that count (personal best, contract, daily game) are played again on the server in a
    // headless Chrome to check their score (App\Jobs\VerifyRunReplay, on the queue): needs Node 22+ and Chrome
    'replay_verifier' => [
        'enabled' => env('KADO_REPLAY_VERIFIER', false),
        'node' => env('KADO_REPLAY_VERIFIER_NODE', 'node'),
        // path of Chrome / Chromium (default: looked for at the usual places)
        'browser' => env('KADO_REPLAY_VERIFIER_BROWSER'),
        'timeout' => (int) env('KADO_REPLAY_VERIFIER_TIMEOUT', 300),
        // games whose replay sometimes ends differently from the live game (determinism bugs, 2026-10): a different
        // score is reported, not sanctioned
        'untrusted_games' => explode(',', env('KADO_REPLAY_VERIFIER_UNTRUSTED_GAMES', '')),
    ],

    'runs' => [
        // A single user can run this amount of games in parallel.
        'max_concurrency' => env('KADO_RUNS_MAX_CONCURRENCY', 50),
    ],

    'poids_plume' => [
        'jackpot' => env('KADO_POIDS_PLUME_JACKPOT', 0),
    ],

    // versions of the game bundles kept for their replays (written by resources/js/games/build-games.mjs)
    'game_builds' => [
        'path' => env('KADO_GAME_BUILDS_PATH', storage_path('app/game-builds')),
    ],

    'security' => [
        'private_key_path' => env('KADO_RSA_PRIVATE_KEY_PATH', storage_path('app/private/privkey.pem')),
        'public_key_path' => env('KADO_RSA_PUBLIC_KEY_PATH', storage_path('app/private/pubkey.pem')),
    ],
];
