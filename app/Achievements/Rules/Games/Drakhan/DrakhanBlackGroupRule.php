<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class DrakhanBlackGroupRule extends DrakhanRule
{
    public function achievementKey(): string
    {
        return 'black_group';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // drop a group of 25 black balls at once
        return $this->best($progress, data_get($event->stats, 'gb'));
    }
}
