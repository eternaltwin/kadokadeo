<?php

namespace Tests\Unit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\Rules\Games\F1Champion\F1ChampionAutobhanRule;
use App\Achievements\Rules\Games\F1Champion\F1ChampionPilotRule;
use App\Achievements\Rules\Games\F1Champion\F1ChampionRiskTakerRule;
use App\Achievements\Rules\Games\F1Champion\F1ChampionSecondLifeRule;
use App\Achievements\Rules\Games\F1Champion\F1ChampionTotalKmRule;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserAchievementProgress;
use Tests\TestCase;

class F1ChampionAchievementRulesTest extends TestCase
{
    public function test_new_stats_are_validated(): void
    {
        $rule = new F1ChampionRiskTakerRule();

        $this->assertTrue($rule->validate($this->event()));
        $this->assertFalse($rule->validate($this->event(['o' => -1])));
        $this->assertFalse($rule->validate($this->event(['m' => 1.5])));
        $this->assertFalse($rule->validate($this->event(['so' => '640'])));
        $this->assertFalse($rule->validate($this->event(['l' => [4, 101]])));
    }

    public function test_distance_rules_convert_25_units_to_one_kilometre(): void
    {
        $progress = $this->progress();

        $totalKm = (new F1ChampionTotalKmRule())->evaluate($this->event(['n' => 26]), $progress);
        $pilot = (new F1ChampionPilotRule())->evaluate($this->event(['m' => 250]), $progress);

        $this->assertSame(1, $totalKm->progress);
        $this->assertSame(['remaining_distance_units' => 1], $totalKm->state);
        $this->assertSame(10, $pilot->progress);
    }

    public function test_risk_taker_and_autobhan_use_best_run_progress(): void
    {
        $progress = $this->progress();

        $riskTaker = (new F1ChampionRiskTakerRule())->evaluate($this->event(['o' => 5]), $progress);
        $autobhan = (new F1ChampionAutobhanRule())->evaluate($this->event(['so' => 640]), $progress);

        $this->assertSame(5, $riskTaker->progress);
        $this->assertSame(20, $autobhan->progress);
    }

    public function test_second_life_requires_full_life_after_dropping_below_five_percent(): void
    {
        $rule = new F1ChampionSecondLifeRule();
        $progress = $this->progress();

        $completed = $rule->evaluate($this->event(['l' => [4, 24, 100]]), $progress);
        $wrongOrder = $rule->evaluate($this->event(['l' => [100, 4, 24]]), $progress);
        $exactlyFive = $rule->evaluate($this->event(['l' => [5, 100]]), $progress);

        $this->assertSame(1, $completed->progress);
        $this->assertFalse($wrongOrder->changed);
        $this->assertFalse($exactlyFive->changed);
    }

    private function event(array $stats = []): GameRunCompleted
    {
        return new GameRunCompleted(
            new User(),
            new Game(['name' => 'F1 Champion']),
            new Run(),
            array_replace([
                'n' => 0,
                'b' => [0, 0, 0, 0, 0],
                'o' => 0,
                'm' => 0,
                'so' => 0,
                'l' => [],
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
