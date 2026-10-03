<?php

return [
    'games_per_day' => env('KADO_GAMES_PER_DAY', 100), // -1 for unlimited

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
