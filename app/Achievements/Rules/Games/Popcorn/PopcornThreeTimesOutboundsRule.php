<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornThreeTimesOutboundsRule extends PopcornRule
{
    public function achievementKey(): string
    {
        return 'three_times_outbounds';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, data_get($event->stats, 'tr', 0));
    }
}
