<?php

namespace App\Achievements\Rules\Games\PiouPiou;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PiouPiouFallingBubblesRule extends PiouPiouRule
{
    public function achievementKey(): string
    {
        return 'falling_bubbles';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $fallingBubbles = data_get($event->stats, 'fb', []);

        return AchievementRuleResult::setProgress(max($progress->current_value, array_sum($fallingBubbles)));
    }
}
