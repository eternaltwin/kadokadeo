<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class FlusheeBigGroupRule extends FlusheeRule
{
    public function achievementKey(): string
    {
        return 'big_group';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the biggest group of one colour exploded in a single move
        return $this->best($progress, data_get($event->stats, 'bg'));
    }
}
