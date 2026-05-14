<?php

namespace App\Console\Commands;

use App\Models\Run;
use Illuminate\Console\Command;

class CleanOldRuns extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kado:clean-old-runs';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean old runs that are more than two months old and have no score.';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        Run::where('created_at', '<', now()->subMonths(2))
            ->whereNull('score')
            ->forceDelete();
    }
}
