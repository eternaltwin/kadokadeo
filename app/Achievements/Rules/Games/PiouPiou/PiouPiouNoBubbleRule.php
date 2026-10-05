<?php

namespace App\Achievements\Rules\Games\PiouPiou;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PiouPiouNoBubbleRule extends PiouPiouRule
{
    public function achievementKey(): string
    {
        return 'no_bubble';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $firstBubbleLevel = data_get($event->stats, 'fbl', 0);

        return AchievementRuleResult::setProgress(max($progress->current_value, $firstBubbleLevel));
    }
}
