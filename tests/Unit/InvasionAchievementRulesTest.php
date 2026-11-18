<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Invasion\InvasionBesiegedRule;
use App\Achievements\Rules\Games\Invasion\InvasionBigKillRule;
use App\Achievements\Rules\Games\Invasion\InvasionBigLossRule;
use App\Achievements\Rules\Games\Invasion\InvasionClearBoardRule;
use App\Achievements\Rules\Games\Invasion\InvasionFourCornersRule;
use App\Achievements\Rules\Games\Invasion\InvasionGoodStudentRule;
use App\Achievements\Rules\Games\Invasion\InvasionImperfectRule;
use App\Achievements\Rules\Games\Invasion\InvasionMonstersKilledRule;
use App\Achievements\Rules\Games\Invasion\InvasionOrangeInOneGameRule;
use App\Achievements\Rules\Games\Invasion\InvasionOrangeMonstersRule;
use App\Achievements\Rules\Games\Invasion\InvasionScoreWithoutOrangeRule;
use App\Achievements\Rules\Games\Invasion\InvasionSymmetryRule;
use App\Achievements\Rules\Games\Invasion\InvasionTripleJackpotRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class InvasionAchievementRulesTest extends TestCase
{
    // a cleared game (m all zero), 24 monsters killed (3 oranges), a group of 16 destroyed in one attack, one soldier lost
    private const STATS = [
        'l' => 1,
        's' => 24,
        'k' => [13, 8, 3],
        'm' => [0, 0, 0],
        'g' => [15],
        'ak' => 16,
        'al' => 1,
        'gc' => 1,
        'ab' => 8,
        'co' => 2,
        'fc' => 0,
        'sym' => 0,
    ];

    public function test_the_cumulative_counts_add_up(): void
    {
        $this->assertSame(124, (new InvasionMonstersKilledRule())->evaluate($this->event([]), $this->progress(100))->progress);
        $this->assertSame(503, (new InvasionOrangeMonstersRule())->evaluate($this->event([]), $this->progress(500))->progress);
    }

    public function test_the_best_of_one_game(): void
    {
        $this->assertSame(3, (new InvasionOrangeInOneGameRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(5, (new InvasionOrangeInOneGameRule())->evaluate($this->event([]), $this->progress(5))->progress);
        $this->assertSame(16, (new InvasionBigKillRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionBigLossRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionTripleJackpotRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(3, (new InvasionTripleJackpotRule())->evaluate($this->event(['gc' => 3]), $this->progress())->progress);
    }

    public function test_the_score_without_orange_only_counts_when_no_orange_was_killed(): void
    {
        $rule = new InvasionScoreWithoutOrangeRule();
        // three oranges killed here: the score does not count
        $this->assertSame(0, $rule->evaluate($this->event([]), $this->progress())->progress);
        // no orange killed: the score counts
        $this->assertSame(13050, $rule->evaluate($this->event(['k' => [20, 5, 0]]), $this->progress())->progress);
        // a higher score already reached stays
        $this->assertSame(20000, $rule->evaluate($this->event(['k' => [20, 5, 0]]), $this->progress(20000))->progress);
    }

    public function test_the_one_time_board_goals(): void
    {
        // cleared board
        $this->assertSame(1, (new InvasionClearBoardRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new InvasionClearBoardRule())->evaluate($this->event(['m' => [1, 0, 0]]), $this->progress())->progress);

        // cleared while losing at least one soldier
        $this->assertSame(1, (new InvasionImperfectRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(0, (new InvasionImperfectRule())->evaluate($this->event(['l' => 0]), $this->progress())->progress);
        $this->assertSame(0, (new InvasionImperfectRule())->evaluate($this->event(['m' => [0, 1, 0]]), $this->progress())->progress);

        // cleared with no soldier in a corner
        $this->assertSame(0, (new InvasionGoodStudentRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionGoodStudentRule())->evaluate($this->event(['co' => 0]), $this->progress())->progress);

        // cleared ending on the four corners
        $this->assertSame(0, (new InvasionFourCornersRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionFourCornersRule())->evaluate($this->event(['fc' => 1]), $this->progress())->progress);
        $this->assertSame(0, (new InvasionFourCornersRule())->evaluate($this->event(['fc' => 1, 'm' => [1, 0, 0]]), $this->progress())->progress);

        // never more than five monsters on the border
        $this->assertSame(0, (new InvasionBesiegedRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionBesiegedRule())->evaluate($this->event(['ab' => 5]), $this->progress())->progress);

        // a full symmetric board
        $this->assertSame(0, (new InvasionSymmetryRule())->evaluate($this->event([]), $this->progress())->progress);
        $this->assertSame(1, (new InvasionSymmetryRule())->evaluate($this->event(['sym' => 1]), $this->progress())->progress);
    }

    public function test_the_stats_must_hold_together(): void
    {
        $rule = new InvasionMonstersKilledRule();

        $this->assertTrue($rule->validate($this->event([])));
        // the game before its achievements only sent l, s, k, m and g
        $this->assertFalse($rule->validate($this->event([], ['l' => 1, 's' => 24, 'k' => [13, 8, 3], 'm' => [0, 0, 0], 'g' => [15]])));
        $this->assertFalse($rule->validate($this->event(['k' => [1, 2]])));
        $this->assertFalse($rule->validate($this->event(['co' => 5])));
        $this->assertFalse($rule->validate($this->event(['fc' => 2])));
        $this->assertFalse($rule->validate($this->event(['ak' => -1])));
    }

    private function event(array $changes, ?array $stats = null): GameRunCompleted
    {
        return new GameRunCompleted(new User(), Game::query()->make(['name' => 'Invasion']), new Run(['score' => 13050]), array_replace($stats ?? self::STATS, $changes));
    }

    private function progress(int $value = 0): UserAchievementProgress
    {
        return new UserAchievementProgress(['current_value' => $value, 'completed_level' => 0]);
    }
}
