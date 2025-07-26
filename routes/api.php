<?php

use Illuminate\Support\Facades\Route;

Route::prefix('/runs')->group(function () {
    Route::post('/games/{game}', [App\Http\Controllers\Api\RunController::class, 'begin'])->name('run.begin');
    Route::post('/{run}/finish', [App\Http\Controllers\Api\RunController::class, 'end'])->name('run.end');
});
