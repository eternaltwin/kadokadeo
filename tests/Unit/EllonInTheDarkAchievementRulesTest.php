<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkChargedHeadRule;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkGumRule;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkSecondaryUpgradesRule;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkSpidersRule;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkTentaclesRule;
use App\Achievements\Rules\Games\EllonInTheDark\EllonInTheDarkWeaponLevelRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class EllonInTheDarkAchievementRulesTest extends TestCase
{
    // a run: 2 spiders (Medusa, k[8]) killed, two secondary upgrades taken (bonus 11 and 10), one tentacle held, hit by
    // a gum ball
    private const STATS = [
        'k' => [0, 163, 24, 8, 2, 5, 4, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 19],
        'b' => [11, 20, 31, 10, 21, 21, 21, 0],
        'd' => 29406,
        'w' => 0,
        't' => 1,
        'g' => 1,
        'h' => 0,
    ];

    public function test_the_counts_add_up(): void
    {
        $this->assertSame(12, (new EllonInTheDarkSpidersRule())->evaluate($this->event([]), $this->progress(10))->progress);
        $this->assertSame(7, (new EllonInTheDarkSecondaryUpgradesRule())->evaluate($this->event([]), $this->progress(5))->progress);
    }

    public function test_the_best_ones(): void
    {
        $weapon = new EllonInTheDarkWeaponLevelRule();
        $this->assertSame(0, $weapon->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(3, $weapon->evaluate($this->event(['w' => 3]), $this->progress())->progress);
        $this->assertSame(2, $weapon->evaluate($this->event(['w' => 1]), $this->progress(2))->progress);

        $this->assertSame(1, (new EllonInTheDarkTentaclesRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(3, (new EllonInTheDarkTentaclesRule())->evaluate($this->event(['t' => 3]), $this->progress())->progress);
        $this->assertSame(1, (new EllonInTheDarkGumRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new EllonInTheDarkGumRule())->evaluate($this->event(['g' => 0]), $this->progress())->progress);
        $this->assertSame(0, (new EllonInTheDarkChargedHeadRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new EllonInTheDarkChargedHeadRule())->evaluate($this->event(['h' => 1]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new EllonInTheDarkSpidersRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements only sent k, b and d
        $this->assertFalse($rule->validate($this->event([], ['k' => self::STATS['k'], 'b' => self::STATS['b'], 'd' => 29406])));
        $this->assertFalse($rule->validate($this->event(['w' => 4])));
        $this->assertFalse($rule->validate($this->event(['t' => 6])));
        $this->assertFalse($rule->validate($this->event(['g' => 2])));
        $this->assertFalse($rule->validate($this->event(['k' => array_fill(0, 22, 0)])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Ellon In The Dark']), new Run(['score' => 58960]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
