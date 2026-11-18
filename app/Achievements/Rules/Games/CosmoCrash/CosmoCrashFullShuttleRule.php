<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CosmoCrashFullShuttleRule extends CosmoCrashRule
{
    public function achievementKey(): string
    {
        return 'full_shuttle';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // launch a shuttle with 8 astronauts on board at once
        return $this->best($progress, data_get($event->stats, 'e'));
    }
}
