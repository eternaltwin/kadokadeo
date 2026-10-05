<?php

namespace App\Achievements\Rules\Games\Atlanteine;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class AtlanteineGhostBusterRule extends AtlanteineRule
{
    public function achievementKey(): string
    {
        return 'ghost_buster';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        foreach ($this->levels($event) as $level) {
            if ($level[3] >= 3) {
                return AchievementRuleResult::setProgress(1);
            }
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
