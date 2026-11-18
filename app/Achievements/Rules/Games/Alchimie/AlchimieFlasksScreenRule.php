<?php

namespace App\Achievements\Rules\Games\Alchimie;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class AlchimieFlasksScreenRule extends AlchimieRule
{
    public function achievementKey(): string
    {
        return 'flasks_screen';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'fs'));
    }
}
