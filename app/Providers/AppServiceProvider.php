<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(\App\Services\RunService::class, fn () => new \App\Services\RunService(config('kado.security')));
        $this->app->bind(\App\Services\GameService::class, fn () => new \App\Services\GameService);
        $this->app->bind(\App\Services\ScoreService::class, fn () => new \App\Services\ScoreService);
        $this->app->bind(\App\Services\PeriodService::class, fn () => new \App\Services\PeriodService);
        $this->app->bind(\App\Services\LeagueService::class, fn ($app) => new \App\Services\LeagueService($app->make(\App\Services\ScoreService::class)));
        $this->app->bind(\App\Services\PoidsPlumeService::class, fn ($app) => new \App\Services\PoidsPlumeService(
            $app->make(\App\Services\LeagueService::class),
            $app->make(\App\Services\ScoreService::class)
        ));
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
