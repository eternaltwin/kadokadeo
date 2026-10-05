<?php

namespace App\Achievements\Rules\Games\ZipZap;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ZipZapFastFinishRule extends ZipZapRule
{
    public function achievementKey(): string
    {
        return 'fast_finish';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $moves = data_get($event->stats, 'm', 0);
        $blackBalloonsPopped = array_sum(array_map(fn ($action) => $action[5], data_get($event->stats, 'pa', [])));

        if ($blackBalloonsPopped === 0 && $moves < 23) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
