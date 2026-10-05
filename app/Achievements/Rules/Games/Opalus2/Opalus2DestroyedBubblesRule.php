<?php

namespace App\Achievements\Rules\Games\Opalus2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Opalus2DestroyedBubblesRule extends Opalus2Rule
{
    public function achievementKey(): string
    {
        return 'destroyed_bubbles';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $sum = array_sum(array_map(fn (array $turn): int => $turn[1], $this->turns($event)));

        return AchievementRuleResult::increment($progress->current_value, $sum);
    }
}
