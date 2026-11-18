<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionBesiegedRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'besieged';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // never let more than five monsters stand on the border at the same time over the whole game
        return $this->best($progress, data_get($event->stats, 'ab') <= 5 ? 1 : 0);
    }
}
