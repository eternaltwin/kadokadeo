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
    protected $description = 'Command description';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        Run::where('created_at', '<', now()->subDays(1))
        ->whereNull('score')
        ->forceDelete();
    }
}
