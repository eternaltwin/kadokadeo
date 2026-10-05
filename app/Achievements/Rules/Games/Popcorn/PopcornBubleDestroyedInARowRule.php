<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornBubleDestroyedInARowRule extends PopcornRule
{
    public function achievementKey(): string
    {
        return 'buble_destroyed_in_a_row';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, $this->maxEventsBetween($event, 0, 3));
    }
}
