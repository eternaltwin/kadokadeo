<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class TwinSpiritWallisScoreRule extends TwinSpiritRule
{
    public function achievementKey(): string
    {
        return 'wallis_score';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the best score ever dealt by Wallis's kills in a run (target: 40.000)
        return $this->best($progress, data_get($event->stats, 'ws'));
    }
}
