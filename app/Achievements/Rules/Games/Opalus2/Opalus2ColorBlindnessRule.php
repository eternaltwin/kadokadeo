<?php

namespace App\Achievements\Rules\Games\Opalus2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Opalus2ColorBlindnessRule extends Opalus2Rule
{
    public function achievementKey(): string
    {
        return 'color_blindness';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $colors = array_unique(array_map(fn (array $turn): int => $turn[0], $this->turns($event)));

        if (count($colors) === 2) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
