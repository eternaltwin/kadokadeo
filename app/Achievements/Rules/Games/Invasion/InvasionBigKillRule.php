<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionBigKillRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'big_kill';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the biggest group of monsters destroyed in one attack
        return $this->best($progress, data_get($event->stats, 'ak'));
    }
}
