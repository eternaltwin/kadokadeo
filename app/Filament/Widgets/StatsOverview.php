<?php

namespace App\Filament\Widgets;

use App\Models\Run;
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
        return [
            Stat::make('Total runs this month', $thisMonthCount)
            ->description(($increase >= 0 ? '+' : '') . $increase . ' than last month')
            ->descriptionIcon($increase >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down'),
        ];
    }
}
