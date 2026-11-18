<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CosmoCrashOutOfFuelRule extends CosmoCrashRule
{
    public function achievementKey(): string
    {
        return 'out_of_fuel';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // run out of fuel
        return $this->best($progress, data_get($event->stats, 'f'));
    }
}
