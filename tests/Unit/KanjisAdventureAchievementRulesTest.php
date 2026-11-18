<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureBearPawsRule;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureFoodRule;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureGoldSpentRule;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureScrollsRule;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureStepsRule;
use App\Achievements\Rules\Games\KanjisAdventure\KanjisAdventureWitchesRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class KanjisAdventureAchievementRulesTest extends TestCase
{
    // a run: 1 witch killed, 837 steps, 75 gold spent, up to 847 food, two scroll types held at once, no bear paw
    private const STATS = ['wk' => 1, 'st' => 837, 'gs' => 75, 'mf' => 847, 's4' => 2, 'bp' => 0];

    public function test_the_counts_add_up(): void
    {
        $this->assertSame(11, (new KanjisAdventureWitchesRule())->evaluate($this->event([]), $this->progress(10))->progress);
        $this->assertSame(1837, (new KanjisAdventureStepsRule())->evaluate($this->event([]), $this->progress(1000))->progress);
        $this->assertSame(175, (new KanjisAdventureGoldSpentRule())->evaluate($this->event([]), $this->progress(100))->progress);
    }

    public function test_the_best_ones(): void
    {
        $this->assertSame(847, (new KanjisAdventureFoodRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(900, (new KanjisAdventureFoodRule())->evaluate($this->event([]), $this->progress(900))->progress);
        $this->assertSame(2, (new KanjisAdventureScrollsRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(4, (new KanjisAdventureScrollsRule())->evaluate($this->event(['s4' => 4]), $this->progress())->progress);
        $this->assertSame(0, (new KanjisAdventureBearPawsRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(2, (new KanjisAdventureBearPawsRule())->evaluate($this->event(['bp' => 2]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new KanjisAdventureWitchesRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements sent nothing
        $this->assertFalse($rule->validate($this->event([], [])));
        // more scroll types than exist
        $this->assertFalse($rule->validate($this->event(['s4' => 5])));
        $this->assertFalse($rule->validate($this->event(['mf' => -1])));
        $this->assertFalse($rule->validate($this->event(['st' => 'x'])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Kanji\'s Adventure']), new Run(['score' => 56385]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
