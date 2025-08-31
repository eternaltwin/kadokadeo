<?php

namespace App\Http\Controllers;

use App\Models\Run;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Gate;

class RunController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth', only: ['show']),
        ];
    }

    public function show(Run $run)
    {
        Gate::authorize('view', $run);
        $run->load('game', 'user');
        Gate::authorize('view', $run->game);

        return view('pages.runs.show', compact('run'));
    }
}
