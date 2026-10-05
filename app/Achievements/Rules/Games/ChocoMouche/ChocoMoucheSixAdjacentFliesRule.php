<?php

namespace App\Achievements\Rules\Games\ChocoMouche;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ChocoMoucheSixAdjacentFliesRule extends ChocoMoucheRule
{
    public function achievementKey(): string
    {
        return 'six_adjacent_flies';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        foreach (data_get($event->stats, 'd', []) as $levelDiscoveries) {
            if (in_array(6, $levelDiscoveries, true)) {
                return $this->bestProgress($progress->current_value, 1);
            }
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
