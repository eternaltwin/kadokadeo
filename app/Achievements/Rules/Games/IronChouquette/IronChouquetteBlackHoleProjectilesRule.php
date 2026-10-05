<?php

namespace App\Achievements\Rules\Games\IronChouquette;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class IronChouquetteBlackHoleProjectilesRule extends IronChouquetteRule
{
    public function achievementKey(): string
    {
        return 'black_hole_projectiles';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }
        $blackHoleSacrifices = data_get($event->stats, 'sak.4', []);

        $maxProjectiles = array_reduce($blackHoleSacrifices, fn ($carry, $sacrifice) => max($carry, $sacrifice[1]), 0);

        return AchievementRuleResult::setProgress(max($progress->current_value, $maxProjectiles));
    }
}
