<?php

namespace App\Achievements\Rules\Games\ChocoMouche;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ChocoMoucheFastLevelOneRule extends ChocoMoucheRule
{
    public function achievementKey(): string
    {
        return 'fast_level_one';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $levelOneTime = data_get($event->stats, 't.0');
        if ($levelOneTime !== null && $levelOneTime < 15 * 32) {
            return $this->bestProgress($progress->current_value, 1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
