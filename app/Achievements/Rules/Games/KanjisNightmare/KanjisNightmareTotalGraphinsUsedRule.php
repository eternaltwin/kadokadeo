<?php

namespace App\Achievements\Rules\Games\KanjisNightmare;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class KanjisNightmareTotalGraphinsUsedRule extends KanjisNightmareRule
{
    public function achievementKey(): string
    {
        return 'total_graphins_used';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $cnt = data_get($event->stats, 'gu', 0);

        return AchievementRuleResult::increment($progress->current_value, $cnt);
    }
}
