<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionBigLossRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'big_loss';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the biggest group of soldiers lost in one enemy attack
        return $this->best($progress, data_get($event->stats, 'al'));
    }
}
