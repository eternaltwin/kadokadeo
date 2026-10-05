<?php

namespace App\Achievements\Rules\Games\Atlanteine;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class AtlanteineLevelReachedRule extends AtlanteineRule
{
    public function achievementKey(): string
    {
        return 'level_reached';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->bestProgress($progress->current_value, count($this->levels($event)));
    }
}
