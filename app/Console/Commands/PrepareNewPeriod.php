<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;

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
    public function handle()
    {
        $period = \App\Models\Period::orderBy('id', 'desc')->first();

        if ($period && $period->start_at->diffInDays(now()) < \App\Models\Period::DAYS_PER_PERIOD) {
            $this->info('Current period is still active, no new period created.');
            return 0;
        }

        if (!$period) {
            $this->info('No period found to close.');
        } else {
            $this->info('Closing old period...');
            // TODO
        }

        $newPeriodStartDate = now()->isMonday() ? now()->startOfDay() : now()->previous(Carbon::MONDAY)->startOfDay();

        $newPeriod = \App\Models\Period::create([
            'start_at' => $newPeriodStartDate,
            'end_at' => $newPeriodStartDate->clone()->addDays(\App\Models\Period::DAYS_PER_PERIOD)->endOfDay(),
        ]);
        $this->info('Period ' . $newPeriod->id . ' created: ' . $newPeriod->start_at->toDateString() . ' to ' . $newPeriod->end_at->toDateString());

        return 0;
    }
}
