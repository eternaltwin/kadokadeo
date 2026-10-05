<?php

namespace App\Achievements\Rules\Games\Kaskade2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Kaskade2BicolorRule extends Kaskade2Rule
{
    public function achievementKey(): string
    {
        return 'bicolor';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $colors = array_unique(array_map(fn (array $click): int => $click[2], $this->clicks($event)));
        if ($event->run->score >= 200000 && count($colors) === 2) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
