<?php

namespace App\Achievements\Rules\Games\KillBulle;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class KillBulleTenWithShurikenRule extends KillBulleRule
{
    public function achievementKey(): string
    {
        return 'ten_with_shuriken';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $popsByPickup = data_get($event->stats, 'bp.2', []);
        $bestPops = min(10, max($popsByPickup ?: [0]));

        if ($bestPops <= $progress->current_value) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::setProgress($bestPops);
    }
}
