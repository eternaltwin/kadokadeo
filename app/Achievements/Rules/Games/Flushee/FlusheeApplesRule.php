<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class FlusheeApplesRule extends FlusheeRule
{
    public function achievementKey(): string
    {
        return 'apples_row';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most apples (bonus gems) lined up on a single row
        return $this->best($progress, data_get($event->stats, 'po'));
    }
}
