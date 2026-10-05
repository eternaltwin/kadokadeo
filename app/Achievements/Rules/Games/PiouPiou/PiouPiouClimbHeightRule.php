<?php

namespace App\Achievements\Rules\Games\PiouPiou;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PiouPiouClimbHeightRule extends PiouPiouRule
{
    public function achievementKey(): string
    {
        return 'climb_height';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $climbHeight = data_get($event->stats, 'ch', 0);

        return AchievementRuleResult::setProgress(max($progress->current_value, $climbHeight));
    }
}
