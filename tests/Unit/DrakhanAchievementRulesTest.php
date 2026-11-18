<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Drakhan\DrakhanBlackBallsRule;
use App\Achievements\Rules\Games\Drakhan\DrakhanBlackGroupRule;
use App\Achievements\Rules\Games\Drakhan\DrakhanBoardPointsRule;
use App\Achievements\Rules\Games\Drakhan\DrakhanClearBoardRule;
use App\Achievements\Rules\Games\Drakhan\DrakhanComboRule;
use App\Achievements\Rules\Games\Drakhan\DrakhanNavyBallRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class DrakhanAchievementRulesTest extends TestCase
{
    // a run: 3 boards emptied, a combo of 7, 72 black balls dropped (12 at once), a navy frozen ball placed
    private const STATS = ['s' => 3, 'mc' => 7, 'nb' => 72, 'gb' => 12, 'nv' => 1];

    public function test_the_black_balls_add_up(): void
    {
        $this->assertSame(172, (new DrakhanBlackBallsRule())->evaluate($this->event([]), $this->progress(100))->progress);
    }

    public function test_the_board_points_follow_the_boards(): void
    {
        $rule = new DrakhanBoardPointsRule();

        // the 3rd board emptied gives 6.000 points
        $this->assertSame(6000, $rule->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(10000, $rule->evaluate($this->event(['s' => 5]), $this->progress())->progress);
        $this->assertSame(8000, $rule->evaluate($this->event([]), $this->progress(8000))->progress);
    }

    public function test_the_best_ones(): void
    {
        $this->assertSame(7, (new DrakhanComboRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(8, (new DrakhanComboRule())->evaluate($this->event([]), $this->progress(8))->progress);
        $this->assertSame(1, (new DrakhanClearBoardRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new DrakhanClearBoardRule())->evaluate($this->event(['s' => 0]), $this->progress())->progress);
        $this->assertSame(1, (new DrakhanNavyBallRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new DrakhanNavyBallRule())->evaluate($this->event(['nv' => 0]), $this->progress())->progress);
        $this->assertSame(12, (new DrakhanBlackGroupRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(25, (new DrakhanBlackGroupRule())->evaluate($this->event(['gb' => 25, 'nb' => 80]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new DrakhanBlackBallsRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements sent nothing
        $this->assertFalse($rule->validate($this->event([], [])));
        $this->assertFalse($rule->validate($this->event(['nv' => 2])));
        // more black balls in one drop than dropped in all
        $this->assertFalse($rule->validate($this->event(['gb' => 100])));
        $this->assertFalse($rule->validate($this->event(['mc' => -1])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Drakhan']), new Run(['score' => 341500]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
