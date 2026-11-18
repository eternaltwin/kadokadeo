<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class ToutCaenBigComboRule extends ToutCaenRule
{
    public function achievementKey(): string
    {
        return 'big_combo';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'c'));
    }
}
