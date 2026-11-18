<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class ToutCaenLevel1ScoreRule extends ToutCaenRule
{
    public function achievementKey(): string
    {
        return 'level1_score';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the best score ever made during level 1 (target: 2.450)
        return $this->best($progress, data_get($event->stats, 'l1'));
    }
}
