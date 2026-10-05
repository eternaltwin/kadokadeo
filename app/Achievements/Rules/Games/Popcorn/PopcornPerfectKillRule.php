<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornPerfectKillRule extends PopcornRule
{
    public function achievementKey(): string
    {
        return 'perfect_kill';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $perfectKill = $this->eventCount($event, 2) === 7 && $this->eventCount($event, 1) === 0;

        return $this->bestProgress($progress->current_value, $perfectKill ? 1 : 0);
    }
}
