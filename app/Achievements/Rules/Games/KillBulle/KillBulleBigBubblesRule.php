<?php

namespace App\Achievements\Rules\Games\KillBulle;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class KillBulleBigBubblesRule extends KillBulleRule
{
    public function achievementKey(): string
    {
        return 'big_bubbles';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $bigBubbles = count(array_filter(data_get($event->stats, 'p', []), fn ($size) => $size === 150));

        if ($bigBubbles <= $progress->current_value) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::setProgress($bigBubbles);
    }
}
