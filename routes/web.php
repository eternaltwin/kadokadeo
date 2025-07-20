<?php

use Illuminate\Support\Facades\Route;

Route::get('/', [App\Http\Controllers\HomeController::class, 'index']);

Route::middleware('guest')->group(function () {
    Route::get('/login', [App\Http\Controllers\LoginController::class, 'login'])->name('login');
    Route::get('/oauth/callback', [App\Http\Controllers\LoginController::class, 'loginCallback']);
});

Route::middleware('auth')->group(function () {
    Route::post('/logout', [App\Http\Controllers\LoginController::class, 'logout'])->name('logout');
    Route::get('/user/settings', [App\Http\Controllers\AccountController::class, 'edit'])->name('account.edit');
    Route::post('/user/settings', [App\Http\Controllers\AccountController::class, 'update'])->name('account.update');
});
