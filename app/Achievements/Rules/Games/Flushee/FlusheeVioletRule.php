<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class FlusheeVioletRule extends FlusheeRule
{
    public function achievementKey(): string
    {
        return 'violet_animals';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most violet animals on the board at once
        return $this->best($progress, data_get($event->stats, 'vi'));
    }
}
