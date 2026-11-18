<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionImperfectRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'imperfect';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // clear every monster but lose at least one soldier along the way
        $done = $this->cleared($event) && data_get($event->stats, 'l') >= 1;

        return $this->best($progress, $done ? 1 : 0);
    }
}
