<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CosmoCrashShuttlesOneGameRule extends CosmoCrashRule
{
    public function achievementKey(): string
    {
        return 'shuttles_one_game';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most shuttles launched in a single run
        return $this->best($progress, data_get($event->stats, 'l'));
    }
}
