<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Spatie\DiscordAlerts\Facades\DiscordAlert;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->dontReportDuplicates();
        $exceptions->report(function (Throwable $e) {
            $t = $e->getTrace()[0];
            $f = data_get($t, 'file', 'unknown file');
            $l = data_get($t, 'line', 'unknown line');
            $fu = data_get($t, 'function', 'unknown function');
            DiscordAlert::to('default')->message(sprintf("```%s\n%s:%s@%s```", $e->getMessage(), $f, $l, $fu));
        });
    })->create();
