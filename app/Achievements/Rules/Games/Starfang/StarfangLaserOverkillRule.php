<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class StarfangLaserOverkillRule extends StarfangRule
{
    public function achievementKey(): string
    {
        return 'laser_overkill';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $killsByBonus = data_get($event->stats, 'kb', []);
        if ($killsByBonus[10] > 0) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
