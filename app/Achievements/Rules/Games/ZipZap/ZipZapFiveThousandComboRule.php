<?php

namespace App\Achievements\Rules\Games\ZipZap;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ZipZapFiveThousandComboRule extends ZipZapRule
{
    public function achievementKey(): string
    {
        return 'five_thousand_combo';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $max = 0;
        foreach (data_get($event->stats, 'pa', []) as $action) {
            $max = max($max, $action[4]);
        }

        return AchievementRuleResult::setProgress(max($progress->current_value, $max));
    }
}
