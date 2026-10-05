<?php

namespace App\Achievements\Rules\Games\Tubulo;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TubuloLevel9ChronoMaxRule extends TubuloRule
{
    public function achievementKey(): string
    {
        return 'level_9_chrono_max';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event) || ($this->levelChronos($event)[7] ?? null) !== 0) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, 1);
    }
}
