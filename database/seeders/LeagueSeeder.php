<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class LeagueSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $leagues = [
            [
                'level' => 1,
                'name' => 'Niveau débutant',
                'promotion_max_slots' => 50,
                'promotion_ratio_divisor' => 3,
                'promotion_min_stars' => 0,
                'promotion_reward' => 100,
            ],
            // [
            //     'level' => 2,
            //     'name' => 'Niveau confirmé',
            //     'promotion_max_slots' => 800,
            //     'promotion_ratio_divisor' => 5,
            //     'promotion_min_stars' => 0,
            //     'promotion_reward' => 200,
            // ],
            // [
            //     'level' => 3,
            //     'name' => 'Niveau vert',
            //     'promotion_max_slots' => 400,
            //     'promotion_ratio_divisor' => 10,
            //     'promotion_min_stars' => 0,
            //     'promotion_reward' => 300,
            // ],
            // [
            //     'level' => 4,
            //     'name' => 'Niveau orange',
            //     'promotion_max_slots' => 300,
            //     'promotion_ratio_divisor' => 15,
            //     'promotion_min_stars' => 0,
            //     'promotion_reward' => 500,
            // ],
            // [
            //     'level' => 5,
            //     'name' => 'Niveau rouge',
            //     'promotion_max_slots' => 100,
            //     'promotion_ratio_divisor' => 50,
            //     'promotion_min_stars' => 1,
            //     'promotion_reward' => 1000,
            // ],
            [
                'level' => 2,
                'name' => 'Niveau bronze',
                'promotion_max_slots' => 20,
                'promotion_ratio_divisor' => 5,
                'promotion_min_stars' => 1,
                'promotion_reward' => 500,
            ],
            [
                'level' => 3,
                'name' => 'Niveau argent',
                'promotion_max_slots' => 5,
                'promotion_ratio_divisor' => 50,
                'promotion_min_stars' => 2,
                'promotion_reward' => 2000,
            ],
            [
                'level' => 4,
                'name' => 'Niveau or',
                'promotion_max_slots' => 1,
                'promotion_ratio_divisor' => null,
                'promotion_min_stars' => 2,
                'promotion_reward' => 5000,
            ],
            [
                'level' => 5,
                'name' => 'Niveau paradis',
                'promotion_max_slots' => null,
                'promotion_ratio_divisor' => null,
                'promotion_min_stars' => null,
                'promotion_reward' => null,
            ],
        ];

        foreach ($leagues as $league) {
            DB::table('leagues')->updateOrInsert(
                ['level' => $league['level']],
                [
                    ...Arr::except($league, ['level']),
                    'created_at' => now(),
                    'updated_at' => now(),
                ]
            );
        }
    }
}
