<?php

namespace App\Achievements\Rules\Games\Opalus2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Opalus2FallenBubblesRule extends Opalus2Rule
{
    public function achievementKey(): string
    {
        return 'fallen_bubbles';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $max = max(array_map(fn (array $turn): int => $turn[2], $this->turns($event)) ?: [0]);

        return AchievementRuleResult::setProgress(max($progress->current_value, $max));
    }
}
