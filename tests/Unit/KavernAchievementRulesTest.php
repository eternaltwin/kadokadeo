<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Kavern\KavernCauliflowersRule;
use App\Achievements\Rules\Games\Kavern\KavernDepthRule;
use App\Achievements\Rules\Games\Kavern\KavernEnergiesRule;
use App\Achievements\Rules\Games\Kavern\KavernLegumesRule;
use App\Achievements\Rules\Games\Kavern\KavernOxygenRule;
use App\Achievements\Rules\Games\Kavern\KavernRockRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class KavernAchievementRulesTest extends TestCase
{
    // a run: 2 energies (b0+b1 = 11), 105 vegetables (b2..7), 4 of them cauliflowers (b7), down to 38 m, 1 rock broken,
    // the oxygen gauge filled, two cauliflowers taken in one level
    private const STATS = ['b' => [10, 1, 35, 26, 18, 16, 6, 4], 'd' => 38, 'k' => 1, 'c' => 309, 'l' => 72, 'o' => 1, 'cf' => 2];

    public function test_the_counts_add_up(): void
    {
        $this->assertSame(155, (new KavernLegumesRule())->evaluate($this->event([]), $this->progress(50))->progress);
        $this->assertSame(21, (new KavernEnergiesRule())->evaluate($this->event([]), $this->progress(10))->progress);
    }

    public function test_the_depth_keeps_the_best(): void
    {
        $rule = new KavernDepthRule();

        $this->assertSame(38, $rule->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(50, $rule->evaluate($this->event([]), $this->progress(50))->progress);
        $this->assertSame(60, $rule->evaluate($this->event(['d' => 60]), $this->progress())->progress);
    }

    public function test_the_unique_ones(): void
    {
        $this->assertSame(1, (new KavernRockRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new KavernRockRule())->evaluate($this->event(['k' => 0]), $this->progress())->progress);
        $this->assertSame(1, (new KavernOxygenRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new KavernOxygenRule())->evaluate($this->event(['o' => 0]), $this->progress())->progress);
        $this->assertSame(2, (new KavernCauliflowersRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new KavernCauliflowersRule())->evaluate($this->event(['cf' => 1, 'b' => [10, 1, 35, 26, 18, 16, 6, 4]]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new KavernLegumesRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the stats of the game before its achievements (no o, no cf)
        $this->assertFalse($rule->validate($this->event([], ['b' => self::STATS['b'], 'd' => 38, 'k' => 1, 'c' => 309, 'l' => 72])));
        $this->assertFalse($rule->validate($this->event(['o' => 2])));
        // more cauliflowers in one level than taken in the whole run
        $this->assertFalse($rule->validate($this->event(['cf' => 5])));
        $this->assertFalse($rule->validate($this->event(['b' => [10, 1, 35, 26, 18, 16, 6]])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Kavern']), new Run(['score' => 61800]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
