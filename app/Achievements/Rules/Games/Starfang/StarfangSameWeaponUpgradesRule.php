<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class StarfangSameWeaponUpgradesRule extends StarfangRule
{
    public function achievementKey(): string
    {
        return 'same_weapon_upgrades';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $weaponUpgrades = array_filter(data_get($event->stats, 'b', []), fn ($bonus) => $bonus >= 0 && $bonus <= 4);
        $counts = array_count_values($weaponUpgrades);
        if (count($counts) > 0 && max($counts) >= 5) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
