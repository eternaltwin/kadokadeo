<?php

use Illuminate\Support\Facades\Route;

Route::get('/user', [App\Http\Controllers\Api\UserController::class, 'index']);
Route::prefix('/runs')->group(function () {
    Route::post('/games/{game}', [App\Http\Controllers\Api\RunController::class, 'begin'])->name('run.begin');
    Route::post('/{run}/finish', [App\Http\Controllers\Api\RunController::class, 'end'])->name('run.end');
});
