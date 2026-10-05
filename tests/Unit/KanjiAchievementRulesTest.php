<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\Kanji\KanjiNoStorkKillScoreRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class KanjiAchievementRulesTest extends TestCase
{
    public function test_no_stork_kill_score_uses_the_run_score_when_no_stork_was_bounced_on(): void
    {
        $result = (new KanjiNoStorkKillScoreRule())->evaluate($this->event(['fksc' => -1], 5000), $this->progress());

        $this->assertSame(5000, $result->progress);
    }

    public function test_no_stork_kill_score_stops_at_a_first_stork_bounced_on_at_zero_points(): void
    {
        $result = (new KanjiNoStorkKillScoreRule())->evaluate($this->event(['fksc' => 0], 5000), $this->progress());

        $this->assertSame(0, $result->progress);
    }

    public function test_first_kill_score_is_validated(): void
    {
        $rule = new KanjiNoStorkKillScoreRule();

        $this->assertTrue($rule->validate($this->event(['fksc' => -1], 5000)));
        $this->assertFalse($rule->validate($this->event(['fksc' => -2], 5000)));
        $this->assertFalse($rule->validate($this->event(['fksc' => 5200], 5000)));
    }

    private function event(array $stats, int $score): GameRunCompleted
    {
        $run = new Run();
        $run->score = $score;
        $run->play_time_seconds = 60;

        return new GameRunCompleted(
            new User(),
            new Game(['name' => 'Kanji']),
            $run,
            array_replace([
                't' => 99,
                'l' => 0,
                'n' => 0,
                'b' => [0, 0, 0],
                'm' => [0, 0, 0],
                'k' => 0,
                'ks' => 0,
                'wj' => 0,
                'bs' => 0,
                'ba' => 0,
                'bas' => 0,
                'lk' => 0,
                'fksc' => -1,
                'fs' => 0,
            ], $stats),
        );
    }

    private function progress(): UserAchievementProgress
    {
        return new UserAchievementProgress([
            'current_value' => 0,
            'state' => [],
        ]);
    }
}
