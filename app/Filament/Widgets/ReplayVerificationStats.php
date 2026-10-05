<?php

namespace App\Filament\Widgets;

use App\Enums\RunVerification;
use App\Models\ReplayVerification;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

// the replays verified on the server (App\Jobs\VerifyRunReplay), on the dashboard and the page of the verifier
class ReplayVerificationStats extends StatsOverviewWidget
{
    protected static ?int $sort = 2;

    protected ?string $pollingInterval = '60s';

    protected ?string $heading = 'Vérification des replays (7 derniers jours)';

    protected function getStats(): array
    {
        $week = ReplayVerification::where('created_at', '>=', now()->subDays(7));
        $counts = (clone $week)->selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');
        $today = ReplayVerification::where('created_at', '>=', now()->subDay())
            ->selectRaw('status, count(*) as total')->groupBy('status')->pluck('total', 'status');
        $count = fn ($counts, RunVerification ...$statuses) => collect($statuses)->sum(fn ($s) => $counts[$s->value] ?? 0);
        $averageMs = (clone $week)->whereIn('status', [RunVerification::VERIFIED, RunVerification::MISMATCH])->avg('duration_ms');

        $cheats = $count($counts, RunVerification::MISMATCH, RunVerification::NO_REPLAY);
        $failures = $count($counts, RunVerification::FAILED);

        return [
            Stat::make('Replays vérifiés', $count($counts, RunVerification::VERIFIED))
                ->description($count($today, RunVerification::VERIFIED).' ces dernières 24 h')
                ->color('success'),
            Stat::make('Triches détectées', $cheats)
                ->description(sprintf('%d score(s) différent(s), %d sans replay valide', $count($counts, RunVerification::MISMATCH), $count($counts, RunVerification::NO_REPLAY)))
                ->color($cheats > 0 ? 'danger' : 'gray'),
            Stat::make('Échecs de vérification', $failures)
                ->description($count($today, RunVerification::FAILED).' ces dernières 24 h')
                ->color($failures > 0 ? 'warning' : 'gray'),
            Stat::make('Durée moyenne', $averageMs === null ? '—' : number_format($averageMs / 1000, 1, ',', ' ').' s')
                ->description('pour rejouer un replay'),
        ];
    }
}
