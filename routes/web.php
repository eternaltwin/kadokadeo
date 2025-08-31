<?php

use Illuminate\Support\Facades\Route;

Route::get('/', [App\Http\Controllers\HomeController::class, 'index']);

Route::get('/login', [App\Http\Controllers\LoginController::class, 'login'])->name('login');
Route::post('/logout', [App\Http\Controllers\LoginController::class, 'logout'])->name('logout');
Route::get('/oauth/callback', [App\Http\Controllers\LoginController::class, 'loginCallback']);
Route::post('/token', [App\Http\Controllers\LoginController::class, 'generateToken']);

Route::get('/user/settings', [App\Http\Controllers\AccountController::class, 'edit'])->name('account.edit');
Route::post('/user/settings', [App\Http\Controllers\AccountController::class, 'update'])->name('account.update');

Route::prefix('/games')->group(function () {
    Route::get('/', [App\Http\Controllers\GameController::class, 'index'])->name('games.index');
    Route::get('/{game}', [App\Http\Controllers\GameController::class, 'show'])->name('games.show');
});

Route::get('/runs/{run}', [App\Http\Controllers\RunController::class, 'show'])->name('runs.show');
