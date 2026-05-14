<?php

namespace Database\Factories;

use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends \Illuminate\Database\Eloquent\Factories\Factory<\App\Models\League>
 */
class LeagueFactory extends Factory
{
    public function definition(): array
    {
        return [
            'level' => $this->faker->numberBetween(1, 5),
            'name' => $this->faker->word(),
        ];
    }
}
