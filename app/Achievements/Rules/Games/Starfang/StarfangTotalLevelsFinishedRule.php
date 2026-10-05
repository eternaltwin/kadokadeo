<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class StarfangTotalLevelsFinishedRule extends StarfangRule
{
    public function achievementKey(): string
    {
        return 'total_levels_finished';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::increment($progress->current_value, count($this->completedLevels(data_get($event->stats, 'l', []))));
    }
}
