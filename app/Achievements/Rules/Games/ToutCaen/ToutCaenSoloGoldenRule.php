<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class ToutCaenSoloGoldenRule extends ToutCaenRule
{
    public function achievementKey(): string
    {
        return 'solo_golden';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'sg'));
    }
}
