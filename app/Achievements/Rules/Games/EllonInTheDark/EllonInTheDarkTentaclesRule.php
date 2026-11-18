<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkTentaclesRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'tentacles';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // hold the three tentacles at once
        return $this->best($progress, data_get($event->stats, 't'));
    }
}
