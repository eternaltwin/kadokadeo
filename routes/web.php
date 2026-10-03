<?php

use Illuminate\Support\Facades\Route;

Route::get('/login', [App\Http\Controllers\LoginController::class, 'login'])->name('login');

// bundle of an old version of a game, for the replays recorded with it (rebuilt from the archive)
Route::get('/gamesdata/builds/{game}/{file}', [App\Http\Controllers\GameBuildController::class, 'bundle'])
    ->where(['game' => '[a-z0-9]+', 'file' => '[0-9a-f]{12}\.js'])
    ->name('game-builds.bundle');

Route::fallback(fn () => view('layouts.default'));
