<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionFourCornersRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'four_corners';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // clear every monster, ending on the four corners (the last four monsters killed are the four corners)
        $done = $this->cleared($event) && data_get($event->stats, 'fc') === 1;

        return $this->best($progress, $done ? 1 : 0);
    }
}
