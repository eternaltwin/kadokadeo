<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornTotalKilledTimesRule extends PopcornRule
{
    public function achievementKey(): string
    {
        return 'total_killed_times';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::increment($progress->current_value, $this->eventCount($event, 2) === 7 ? 1 : 0);
    }
}
