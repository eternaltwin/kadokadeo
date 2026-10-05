<?php

namespace App\Achievements\Rules\Games\Atlanteine;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class AtlanteineBoxesMovedRule extends AtlanteineRule
{
    public function achievementKey(): string
    {
        return 'boxes_moved';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $sum = array_sum(array_map(fn (array $level): int => $level[2], $this->levels($event)));

        return AchievementRuleResult::increment($progress->current_value, $sum);
    }
}
