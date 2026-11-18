<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KavernOxygenRule extends KavernRule
{
    public function achievementKey(): string
    {
        return 'oxygen';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // fill the oxygen gauge to the max at least once
        return $this->best($progress, data_get($event->stats, 'o'));
    }
}
