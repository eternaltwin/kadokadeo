<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KavernDepthRule extends KavernRule
{
    public function achievementKey(): string
    {
        return 'depth';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'd'));
    }
}
