<?php

namespace App\Achievements\Rules\Games\Tubulo;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TubuloMinScoreRule extends TubuloRule
{
    public function achievementKey(): string
    {
        return 'min_score';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event) || $event->run->score !== 200) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, 1);
    }
}
