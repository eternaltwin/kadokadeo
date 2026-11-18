<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionSymmetryRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'symmetry';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // fill every board cell while keeping the vertical mirror symmetry of the two camps
        return $this->best($progress, data_get($event->stats, 'sym'));
    }
}
