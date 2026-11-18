<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KavernRockRule extends KavernRule
{
    public function achievementKey(): string
    {
        return 'rock';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // break at least one rock in a run
        return $this->best($progress, min(1, data_get($event->stats, 'k')));
    }
}
