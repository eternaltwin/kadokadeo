<?php

namespace App\Filament\Widgets;

use App\Models\Run;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends StatsOverviewWidget
{
    protected function getStats(): array
    {
        $thisMonthCount = Run::whereMonth('created_at', now()->month)
            ->whereNotNull('completed_at')
            ->count();
        $prevMonthCount = Run::whereMonth('created_at', now()->subMonth()->month)
            ->whereNotNull('completed_at')
            ->count();
        $increase = $thisMonthCount - $prevMonthCount;

        $usersMonthCount = User::whereMonth('created_at', now()->month)->count();

        $activePlayersCount = User::whereHas('runs', function ($query) {
            $query->whereNotNull('completed_at')->whereMonth('created_at', now()->month);
        })->count();
        $activePlayersPrevMonthCount = User::whereHas('runs', function ($query) {
            $query->whereNotNull('completed_at')->whereMonth('created_at', now()->subMonth()->month);
        })->count();
        $activePlayersIncrease = $activePlayersCount - $activePlayersPrevMonthCount;

        return [
            Stat::make('Parties terminées ce mois-ci', $thisMonthCount)
                ->description(($increase >= 0 ? '+' : '').$increase.' par rapport au mois dernier')
                ->descriptionIcon($increase >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down'),
            Stat::make('Utilisateurs', User::count())
                ->description('+'.$usersMonthCount.' ce mois-ci'),
            Stat::make('Joueurs actifs ce mois-ci', $activePlayersCount)
                ->description(($activePlayersIncrease >= 0 ? '+' : '').$activePlayersIncrease.' par rapport au mois dernier'),
        ];
    }
}
