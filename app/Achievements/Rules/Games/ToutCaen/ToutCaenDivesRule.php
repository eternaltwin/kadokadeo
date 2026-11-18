<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class ToutCaenDivesRule extends ToutCaenRule
{
    public function achievementKey(): string
    {
        return 'dives';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'd'));
    }
}
