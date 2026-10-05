<?php

namespace App\Achievements\Rules\Games\Tubulo;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TubuloLevel10WithoutRetryRule extends TubuloRule
{
    public function achievementKey(): string
    {
        return 'level_10_without_retry';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)
            || count($this->completedLevels($event)) < 9
            || count($this->resets($event)) > 0) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, 1);
    }
}
