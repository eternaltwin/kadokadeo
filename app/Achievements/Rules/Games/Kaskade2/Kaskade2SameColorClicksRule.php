<?php

namespace App\Achievements\Rules\Games\Kaskade2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Kaskade2SameColorClicksRule extends Kaskade2Rule
{
    public function achievementKey(): string
    {
        return 'same_color_clicks';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $longestSequence = 0;
        $currentSequence = 0;
        $previousColor = null;

        foreach ($this->clicks($event) as $click) {
            $color = $click[2];
            $currentSequence = $color === $previousColor ? $currentSequence + 1 : 1;
            $longestSequence = max($longestSequence, $currentSequence);
            $previousColor = $color;
        }

        return AchievementRuleResult::setProgress(max($progress->current_value, $longestSequence));
    }
}
