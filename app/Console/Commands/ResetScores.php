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
    protected $signature = 'kado:reset-scores {gameId? : Optional game id to reset}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Reset game scores (all games or one game)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $gameId = $this->argument('gameId');

        $query = Run::query();
        if ($gameId !== null) {
            $query->where('game_id', $gameId);
        }

        $query->update(['replay' => null]);
        $query->delete();
    }
}
