<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionGoodStudentRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'good_student';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // clear every monster while leaving no soldier in any of the four corners
        $done = $this->cleared($event) && data_get($event->stats, 'co') === 0;

        return $this->best($progress, $done ? 1 : 0);
    }
}
