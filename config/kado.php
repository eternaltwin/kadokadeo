<?php

return [
    'games_per_day' => env('KADO_GAMES_PER_DAY', 100), // -1 for unlimited

    'runs' => [
        // A single user can run this amount of games in parallel.
        'max_concurrency' => env('KADO_RUNS_MAX_CONCURRENCY', 50),
    ],

    'security' => [
        'private_key' => env('KADO_RSA_PRIVATE_KEY'),
        'public_key' => env('KADO_RSA_PUBLIC_KEY'),
    ]
];
