<?php

namespace App\Achievements\Rules\Games\Tubulo;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TubuloLevelResetsRule extends TubuloRule
{
    public function achievementKey(): string
    {
        return 'level_resets';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::increment($progress->current_value, count(array_unique($this->resets($event))));
    }
}
