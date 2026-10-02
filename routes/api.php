<?php

use Illuminate\Support\Facades\Route;

Route::get('/oauth/callback', [App\Http\Controllers\LoginController::class, 'loginCallback']);
Route::post('/logout', [App\Http\Controllers\LoginController::class, 'logout']);

Route::get('/user', [App\Http\Controllers\Api\UserController::class, 'index']);
Route::get('/users/{user:etwin_id}', [App\Http\Controllers\Api\UserController::class, 'show'])->whereUuid('etwin_id');
Route::get('/users/{user:etwin_id}/history', [App\Http\Controllers\Api\UserController::class, 'showHistory'])->whereUuid('etwin_id');

Route::get('/announcement', [App\Http\Controllers\Api\AnnouncementController::class, 'show'])
    ->middleware('cache.headers:public;max_age=60;etag');

Route::get('/period/current',[App\Http\Controllers\Api\PeriodController::class, 'current']);

Route::get('/daily/game', [App\Http\Controllers\Api\GameController::class, 'daily']);
Route::get('/daily/scores', [App\Http\Controllers\Api\GameScoreController::class, 'dailyScores']);

Route::resource('/games', App\Http\Controllers\Api\GameController::class)->only(['index', 'show'])->whereNumber('game');
Route::get('/games/{game}/scores', [App\Http\Controllers\Api\GameScoreController::class, 'index'])->whereNumber('game');
Route::get('/games/{game}/ranking', [App\Http\Controllers\Api\GameScoreController::class, 'search'])->whereNumber('game');

Route::prefix('/runs')->group(function () {
    Route::get('/{run}', [App\Http\Controllers\Api\RunController::class, 'show'])->whereUlid('run');
    Route::post('/games/{game}', [App\Http\Controllers\Api\RunController::class, 'begin'])->whereNumber('game');
    Route::post('/{run}/finish', [App\Http\Controllers\Api\RunController::class, 'end'])->whereUlid('run');
});
