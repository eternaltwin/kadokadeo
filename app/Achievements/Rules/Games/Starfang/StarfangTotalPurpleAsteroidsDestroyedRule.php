<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class StarfangTotalPurpleAsteroidsDestroyedRule extends StarfangRule
{
    public function achievementKey(): string
    {
        return 'total_purple_asteroids_destroyed';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $purpleAsteroids = array_sum(array_map(fn ($level) => $level[2], data_get($event->stats, 'l', [])));

        return AchievementRuleResult::increment($progress->current_value, (int) $purpleAsteroids);
    }
}
