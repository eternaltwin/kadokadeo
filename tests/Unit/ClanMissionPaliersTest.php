<?php

namespace Tests\Unit;

use App\Services\ClanMissionPaliers;
use PHPUnit\Framework\TestCase;

// the scores to reach of the steps of the missions: easy and hard steps mixed, beyond the red star
class ClanMissionPaliersTest extends TestCase
{
    private function paliers(array $values = []): ClanMissionPaliers
    {
        return ClanMissionPaliers::fromArray($values + [
            'mission_paliers_every' => 3,
            'mission_hard_share_min' => 0.2,
            'mission_hard_share_step' => 0.05,
            'mission_hard_share_max' => 0.5,
            'mission_easy_steps' => 1,
            'mission_spread_paliers' => 3,
            'mission_beyond_last_star' => 0.1,
        ]);
    }

    public function test_the_paliers_of_a_game_go_beyond_the_red_star_up_to_its_score_1500(): void
    {
        $scores = $this->paliers()->scores([3000, 1000, 2000], 4000);

        $this->assertSame([500.0, 1000.0, 1500.0, 2000.0, 2500.0, 3000.0], array_slice($scores, 0, 6));
        $this->assertCount(16, $scores);
        $this->assertEqualsWithDelta(3100, $scores[6], .01);
        $this->assertEqualsWithDelta(4000, $scores[15], .01);
        // without a "Score 1500" above the red star: nothing beyond it
        $this->assertCount(6, $this->paliers()->scores([1000, 2000, 3000], null));
        $this->assertCount(6, $this->paliers()->scores([1000, 2000, 3000], 2500));
        $this->assertCount(6, $this->paliers(['mission_beyond_last_star' => 0])->scores([1000, 2000, 3000], 4000));
    }

    public function test_a_mission_mixes_an_easy_step_hard_steps_and_steps_between(): void
    {
        $paliers = $this->paliers();

        // the first missions: everything at half the green star
        $this->assertSame([0, 0, 0, 0, 0, 0], $paliers->levels(1, 6));
        $this->assertSame(1, $paliers->topPalier(4));
        // mission 13 (top palier 4): 1 easy step, 2 hard ones (20 % + 4 x 5 %), the others under the top palier
        $this->assertSame([0, 1, 2, 3, 4, 4], $paliers->levels(13, 6));
        // much later: the hard steps are half of them at most, the easy step is still there
        $levels = $paliers->levels(46, 6);
        $this->assertSame(15, $paliers->topPalier(46));
        $this->assertSame(0, $levels[0]);
        $this->assertSame(3, count(array_keys($levels, 15)));
        // the top palier stops at the last one
        $this->assertSame(15, $paliers->topPalier(1000));
        // a single step: the hard one
        $this->assertSame([4], $paliers->levels(13, 1));
    }

    public function test_the_labels_of_the_preview(): void
    {
        $paliers = $this->paliers();

        $this->assertSame('½ verte', $paliers->label(0));
        $this->assertSame('rouge', $paliers->label(5));
        $this->assertSame('rouge +30 %', $paliers->label(8));
    }
}
