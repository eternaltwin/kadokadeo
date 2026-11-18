<?php

namespace App\Achievements\Rules\Games\Alchimie2;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class Alchimie2FlyRule extends Alchimie2Rule
{
    public function achievementKey(): string
    {
        return 'fly';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'f'));
    }
}
