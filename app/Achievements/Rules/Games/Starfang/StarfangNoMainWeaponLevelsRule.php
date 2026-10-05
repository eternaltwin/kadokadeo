<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class StarfangNoMainWeaponLevelsRule extends StarfangRule
{
    public function achievementKey(): string
    {
        return 'no_main_weapon_levels';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $levels = array_filter($this->completedLevels(data_get($event->stats, 'l', [])), fn ($level) => $level[5] === 0);

        return AchievementRuleResult::setProgress(max($progress->current_value, count($levels)));
    }
}
