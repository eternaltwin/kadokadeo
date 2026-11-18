<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashAstronautsRule;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashFullShuttleRule;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashOutOfFuelRule;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashShuttleLaunchesRule;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashShuttlesOneGameRule;
use App\Achievements\Rules\Games\CosmoCrash\CosmoCrashVipRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class CosmoCrashAchievementRulesTest extends TestCase
{
    // a run: 9 shuttles launched, 40 astronauts dropped, out of fuel once, a VIP shuttle, no full shuttle
    private const STATS = ['l' => 9, 'a' => 40, 'f' => 1, 'v' => 1, 'e' => 0];

    public function test_the_counts_add_up(): void
    {
        $this->assertSame(34, (new CosmoCrashShuttleLaunchesRule())->evaluate($this->event([]), $this->progress(25))->progress);
        $this->assertSame(1040, (new CosmoCrashAstronautsRule())->evaluate($this->event([]), $this->progress(1000))->progress);
    }

    public function test_the_best_ones(): void
    {
        $shuttles = new CosmoCrashShuttlesOneGameRule();
        $this->assertSame(9, $shuttles->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(10, $shuttles->evaluate($this->event([]), $this->progress(10))->progress);
        $this->assertSame(12, $shuttles->evaluate($this->event(['l' => 12]), $this->progress())->progress);

        $this->assertSame(1, (new CosmoCrashOutOfFuelRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new CosmoCrashOutOfFuelRule())->evaluate($this->event(['f' => 0]), $this->progress())->progress);
        $this->assertSame(1, (new CosmoCrashVipRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new CosmoCrashFullShuttleRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new CosmoCrashFullShuttleRule())->evaluate($this->event(['e' => 1]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new CosmoCrashShuttleLaunchesRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements sent nothing
        $this->assertFalse($rule->validate($this->event([], [])));
        $this->assertFalse($rule->validate($this->event(['l' => -1])));
        $this->assertFalse($rule->validate($this->event(['l' => '9'])));
        $this->assertFalse($rule->validate($this->event(['f' => 2])));
        $this->assertFalse($rule->validate($this->event(['v' => true])));
        $this->assertFalse($rule->validate($this->event(['a' => [1, 2]])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Cosmo Crash']), new Run(['score' => 120000]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
