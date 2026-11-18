<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CosmoCrashVipRule extends CosmoCrashRule
{
    public function achievementKey(): string
    {
        return 'vip';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // launch a shuttle carrying a green, a blue and a rare (type 3) astronaut at once
        return $this->best($progress, data_get($event->stats, 'v'));
    }
}
