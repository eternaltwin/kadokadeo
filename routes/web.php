<?php

use Illuminate\Support\Facades\Route;

Route::get('/login', [App\Http\Controllers\LoginController::class, 'login'])->name('login');

Route::fallback(fn () => view('layouts.default'));
