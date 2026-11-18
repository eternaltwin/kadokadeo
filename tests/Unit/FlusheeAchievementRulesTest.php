<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Flushee\FlusheeAnimalsRule;
use App\Achievements\Rules\Games\Flushee\FlusheeApplesRule;
use App\Achievements\Rules\Games\Flushee\FlusheeBigGroupRule;
use App\Achievements\Rules\Games\Flushee\FlusheeComboRule;
use App\Achievements\Rules\Games\Flushee\FlusheeTokensRule;
use App\Achievements\Rules\Games\Flushee\FlusheeVioletRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class FlusheeAchievementRulesTest extends TestCase
{
    // a run: 14 moves, best combo 5.100 points, 120 animals exploded, 6 big token gems grabbed, up to 9 violet animals
    // at once, 2 apples lined up, a group of 7
    private const STATS = [
        'n' => 14,
        's' => [0, 2200, 0, 3600, 0, 5100, 0, 0, 0, 0, 0, 0, 0, 0],
        't' => [1, 2, 1, 3, 1, 4, 1, 1, 1, 1, 1, 1, 1, 1],
        'a' => 120,
        'tk' => 6,
        'vi' => 9,
        'po' => 2,
        'bg' => 7,
    ];

    public function test_the_counts_add_up(): void
    {
        $this->assertSame(220, (new FlusheeAnimalsRule())->evaluate($this->event([]), $this->progress(100))->progress);
        $this->assertSame(16, (new FlusheeTokensRule())->evaluate($this->event([]), $this->progress(10))->progress);
    }

    public function test_the_best_ones(): void
    {
        $combo = new FlusheeComboRule();
        $this->assertSame(5100, $combo->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(6000, $combo->evaluate($this->event([]), $this->progress(6000))->progress);
        // no move scored: the best combo is 0
        $this->assertSame(0, $combo->evaluate($this->event(['s' => [], 't' => []]), $this->progress())->progress);

        $this->assertSame(9, (new FlusheeVioletRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(12, (new FlusheeVioletRule())->evaluate($this->event(['vi' => 12]), $this->progress())->progress);
        $this->assertSame(2, (new FlusheeApplesRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(7, (new FlusheeBigGroupRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(8, (new FlusheeBigGroupRule())->evaluate($this->event(['bg' => 8]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new FlusheeAnimalsRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements only sent n, s and t
        $this->assertFalse($rule->validate($this->event([], ['n' => 14, 's' => self::STATS['s'], 't' => self::STATS['t']])));
        // s and t must line up (one entry per move)
        $this->assertFalse($rule->validate($this->event(['t' => [1, 2]])));
        $this->assertFalse($rule->validate($this->event(['a' => -1])));
        $this->assertFalse($rule->validate($this->event(['vi' => '9'])));
        $this->assertFalse($rule->validate($this->event(['bg' => null])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Flushee']), new Run(['score' => 48000]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
