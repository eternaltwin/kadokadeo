<?php

namespace App\Achievements\Rules\Games\ZipZap;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ZipZapEmptyShotsRule extends ZipZapRule
{
    public function achievementKey(): string
    {
        return 'empty_shots';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $emptyShots = count(array_filter(data_get($event->stats, 'pa', []), fn ($action) => array_sum($action) === 0));

        return AchievementRuleResult::increment($progress->current_value, min(10, $emptyShots));
    }
}
