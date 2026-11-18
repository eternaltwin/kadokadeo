<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class DrakhanNavyBallRule extends DrakhanRule
{
    public function achievementKey(): string
    {
        return 'navy_ball';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // place a frozen navy-coloured ball
        return $this->best($progress, data_get($event->stats, 'nv'));
    }
}
