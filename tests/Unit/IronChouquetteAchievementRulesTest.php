<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\IronChouquette\IronChouquetteSameBonusRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use Tests\TestCase;

class IronChouquetteAchievementRulesTest extends TestCase
{
    public function test_a_bonus_replaces_the_first_slot_when_inventory_is_full(): void
    {
        $iterations = $this->iterations([0, 1, 2, 100, 3]);

        $this->assertSame([[1, 2, -1], 100, 0], $iterations[3]);
        $this->assertSame([[1, 2, 3], 3, -1], $iterations[4]);
    }

    public function test_a_manual_sacrifice_removes_the_last_occupied_slot(): void
    {
        $iterations = $this->iterations([0, 1, 2, 102]);

        $this->assertSame([[0, 1, -1], 102, 2], $iterations[3]);
    }

    public function test_bonus_six_adds_an_empty_slot(): void
    {
        $iterations = $this->iterations([0, 6]);

        $this->assertSame([[0, -1, -1, -1], 6, -1], $iterations[1]);
    }

    private function iterations(array $bonusIds): array
    {
        $event = new GameRunCompleted(
            new User(),
            new Game(['name' => 'Iron Chouquette']),
            new Run(),
            ['b' => array_map(fn (int $id) => [0, $id], $bonusIds)],
        );
        $iterations = [];

        (new IronChouquetteSameBonusRule())->iterateThroughBonuses(
            $event,
            function (array $slots, int $bonus, int $removedBonus) use (&$iterations): void {
                $iterations[] = [$slots, $bonus, $removedBonus];
            },
        );

        return $iterations;
    }
}
