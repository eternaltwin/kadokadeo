<?php

namespace App\Achievements\Rules\Games\Kaskade2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Kaskade2RgbRule extends Kaskade2Rule
{
    public function achievementKey(): string
    {
        return 'rgb';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $sequence = [0, 2, 1];
        foreach ($this->clicks($event) as $index => $click) {
            if ($click[2] !== $sequence[$index % count($sequence)]) {
                return AchievementRuleResult::unchanged($progress->current_value);
            }
        }

        if ($event->run->score >= 160000) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
