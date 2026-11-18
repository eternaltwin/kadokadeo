<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class ToutCaenFastLevelRule extends ToutCaenRule
{
    public function achievementKey(): string
    {
        return 'fast_level';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // fl: fewest dives used to clear a level >= 10 (-1: none cleared)
        $fast = data_get($event->stats, 'fl');

        return $this->best($progress, $fast !== -1 && $fast <= 3 ? 1 : 0);
    }
}
