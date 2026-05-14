<?php

namespace Database\Factories;

use App\Models\Game;
use App\Models\Period;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\Run>
 */
class RunFactory extends Factory
{
    public function definition(): array
    {
        return [
            'period_id' => Period::factory(),
            'game_id' => Game::factory(),
            'user_id' => User::factory(),
            'league_id' => null,
            'contract_score' => 0,
            'contract_points' => 0,
            'score' => fake()->numberBetween(0, 1000),
            'play_time_seconds' => fake()->numberBetween(1, 300),
            'completed_at' => now(),
        ];
    }
}
