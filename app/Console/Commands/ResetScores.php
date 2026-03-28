<?php

namespace App\Console\Commands;

use App\Models\Run;
use Illuminate\Console\Command;

class ResetScores extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kado:reset-scores';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Reset all game scores';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        Run::query()->update(['replay' => null]);
        Run::query()->delete();
    }
}
