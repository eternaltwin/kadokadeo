<?php

namespace App\Http\Middleware;

use App\Support\LocaleResolver;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// The messages of the API in the language of the player. Only the API: the admin panel stays in French.
class UseLanguageOfThePlayer
{
    public function handle(Request $request, Closure $next): Response
    {
        app()->setLocale(LocaleResolver::forRequest($request));

        return $next($request);
    }
}
