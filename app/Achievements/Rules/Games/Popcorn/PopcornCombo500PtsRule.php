<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornCombo500PtsRule extends PopcornRule
{
    private const COMBO_SCORES = [25, 50, 75, 100, 150, 200, 300, 400, 500];

    public function achievementKey(): string
    {
        return 'combo_500_pts';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $comboIndex = min($this->maxEventsBetween($event, 0, 3), count(self::COMBO_SCORES));
        $comboScore = $comboIndex >= 0 ? self::COMBO_SCORES[$comboIndex] : 0;

        return $this->bestProgress($progress->current_value, $comboScore);
    }
}
