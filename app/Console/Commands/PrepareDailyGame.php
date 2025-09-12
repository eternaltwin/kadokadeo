<?php

namespace App\Console\Commands;

use App\Models\DailyGame;
use App\Models\Game;
use App\Services\GameService;
use Illuminate\Console\Command;

class PrepareDailyGame extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kado:prepare-daily-game';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Add a new daily game for today';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Check if a daily game already exists for today
        $existing = DailyGame::where('day', now()->today())->first();
        if ($existing) {
            $this->info('Daily game already exists for today.');
            $this->info("Game ID: {$existing->game_id} ({$existing->game->name}), Contract: {$existing->contract_score} for {$existing->contract_points} points.");

            return 0;
        }

        // Pick a random active game
        $game = Game::where('is_active', true)
            ->inRandomOrder()
            ->first();

        if (!$game) {
            $this->error('No active game found');

            return 1;
        }
        $gameService = app(GameService::class);

        [$contract, $points] = $gameService->getContract($game);
        $game->dailyGames()->create([
            'day' => now()->today(),
            'seed' => $gameService->generateSeed(),
            'contract_score' => $contract,
            'contract_points' => $points,
        ]);

        $this->info("Daily game for '{$game->name}' created: score {$contract} to win {$points} kado points.");
    }
}
