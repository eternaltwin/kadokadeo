<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudAmmoUsedRule;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudMachineGunRule;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudMissilesDestroyedRule;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudMissilesInOneExplosionRule;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudRainbowRule;
use App\Achievements\Rules\Games\Crepuscud\CrepuscudSurgicalStrikeRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class CrepuscudAchievementRulesTest extends TestCase
{
    // a game: 234 missiles destroyed, 120 munitions fired, a wave that took six missiles, 25 missiles reached the ground
    private const STATS = [
        'md' => 234,
        'mu' => 120,
        'me' => 6,
        'gl' => 25,
        'mg' => 0,
        'rb' => 0,
    ];

    public function test_the_cumulative_counts_add_up(): void
    {
        $this->assertSame(334, (new CrepuscudMissilesDestroyedRule())->evaluate($this->event([]), $this->progress(100))->progress);
        $this->assertSame(620, (new CrepuscudAmmoUsedRule())->evaluate($this->event([]), $this->progress(500))->progress);
    }

    public function test_the_best_wave_is_kept(): void
    {
        $rule = new CrepuscudMissilesInOneExplosionRule();
        $this->assertSame(6, $rule->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(7, $rule->evaluate($this->event(['me' => 5]), $this->progress(7))->progress);
    }

    public function test_the_one_time_goals(): void
    {
        // empty then refill the ammo
        $this->assertSame(0, (new CrepuscudMachineGunRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new CrepuscudMachineGunRule())->evaluate($this->event(['mg' => 1]), $this->progress())->progress);

        // lose with exactly three missiles on the ground
        $this->assertSame(0, (new CrepuscudSurgicalStrikeRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new CrepuscudSurgicalStrikeRule())->evaluate($this->event(['gl' => 3]), $this->progress())->progress);
        $this->assertSame(0, (new CrepuscudSurgicalStrikeRule())->evaluate($this->event(['gl' => 2]), $this->progress())->progress);

        // one wave of each special colour
        $this->assertSame(0, (new CrepuscudRainbowRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new CrepuscudRainbowRule())->evaluate($this->event(['rb' => 1]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new CrepuscudMissilesDestroyedRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements sent an empty object
        $this->assertFalse($rule->validate($this->event([], [])));
        $this->assertFalse($rule->validate($this->event(['me' => -1])));
        $this->assertFalse($rule->validate($this->event(['mg' => 2])));
        $this->assertFalse($rule->validate($this->event(['gl' => '3'])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Crepuscud']), new Run(['score' => 160000]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
