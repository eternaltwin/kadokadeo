<?php

namespace App\Console\Commands;

use App\Models\Period;
use App\Services\ClanPeriodService;
use App\Services\LeagueService;
use App\Services\PoidsPlumeService;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

class PrepareNewPeriod extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kado:prepare-new-period';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Terminates the current period and prepares a new one.';

    /**
     * Execute the console command.
     */
    public function handle(LeagueService $leagueService, PoidsPlumeService $poidsPlumeService, ClanPeriodService $clanPeriodService)
    {
        $period = Period::orderBy('id', 'desc')->first();

        // the command runs every Monday: the Monday in the middle of a period does nothing (the players are promoted
        // only at the end of a period)
        if ($period && $period->start_at->diffInDays(now()) < Period::DAYS_PER_PERIOD) {
            $previousPeriod = Period::query()
                ->where('id', '<', $period->id)
                ->orderByDesc('id')
                ->first();

            if ($previousPeriod) {
                $this->closePeriod($previousPeriod, $period, $leagueService, $poidsPlumeService, $clanPeriodService);
            }

            $this->info('Current period is still active, no new period created.');

            return 0;
        }

        if (!$period) {
            $this->info('No period found to close.');
        }

        $newPeriodStartDate = now()->isMonday() ? now()->startOfDay() : now()->previous(Carbon::MONDAY)->startOfDay();

        // the new period becomes current (Period::current) only once the memberships are carried over and the players
        // promoted: a run started during the close would otherwise take the league of before the promotion, and its
        // membership would collide with the one the close inserts (league_memberships_user_id_period_id_game_id_unique)
        DB::transaction(function () use ($period, $newPeriodStartDate, $leagueService, $poidsPlumeService, $clanPeriodService) {
            $newPeriod = Period::create([
                'start_at' => $newPeriodStartDate,
                'end_at' => $newPeriodStartDate->clone()->addDays(Period::DAYS_PER_PERIOD)->endOfDay(),
            ]);
            $this->info('Period '.$newPeriod->id.' created: '.$newPeriod->start_at->toDateString().' to '.$newPeriod->end_at->toDateString());

            if ($period) {
                $this->info('Closing period '.$period->id.'...');
                $this->closePeriod($period, $newPeriod, $leagueService, $poidsPlumeService, $clanPeriodService);
            }
        });

        return 0;
    }

    private function closePeriod(Period $period, Period $nextPeriod, LeagueService $leagueService, PoidsPlumeService $poidsPlumeService, ClanPeriodService $clanPeriodService): void
    {
        $this->info('Closing period '.$period->id.'...');

        $leagueService->closePeriod($period, $nextPeriod);
        $poidsPlumeService->closePeriod($period);
        $clanPeriodService->closePeriod($period);
    }
}
