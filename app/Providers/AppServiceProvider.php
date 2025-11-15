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
        $this->app->bind(\App\Services\GameService::class, fn () => new \App\Services\GameService());
        $this->app->bind(\App\Services\ScoreService::class, fn () => new \App\Services\ScoreService());
        $this->app->bind(\App\Services\PeriodService::class, fn () => new \App\Services\PeriodService());
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
