<?php

use Illuminate\Support\Facades\Route;

Route::get('/oauth/callback', [App\Http\Controllers\LoginController::class, 'loginCallback']);
Route::post('/logout', [App\Http\Controllers\LoginController::class, 'logout']);

Route::get('/user', [App\Http\Controllers\Api\UserController::class, 'index']);

Route::get('/period/current', [App\Http\Controllers\Api\PeriodController::class, 'current']);

Route::get('/daily/game', [App\Http\Controllers\Api\GameController::class, 'daily']);
Route::get('/daily/scores', [App\Http\Controllers\Api\GameScoreController::class, 'dailyScores']);

Route::resource('/games', App\Http\Controllers\Api\GameController::class)->only(['index', 'show']);
Route::get('/games/{game}/scores', [App\Http\Controllers\Api\GameScoreController::class, 'index']);
Route::get('/games/{game}/ranking', [App\Http\Controllers\Api\GameScoreController::class, 'search']);

Route::prefix('/runs')->group(function () {
    Route::get('/{run}', [App\Http\Controllers\Api\RunController::class, 'show']);
    Route::post('/games/{game}', [App\Http\Controllers\Api\RunController::class, 'begin']);
    Route::post('/{run}/finish', [App\Http\Controllers\Api\RunController::class, 'end']);
});
