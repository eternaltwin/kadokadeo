<?php

namespace Database\Factories;

use App\Models\Game;
use App\Models\League;
use App\Models\Period;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\LeagueMembership>
 */
class LeagueMembershipFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'period_id' => Period::factory(),
            'game_id' => Game::factory(),
            'league_id' => League::query()->where('level', 1)->value('id'),
        ];
    }
}
