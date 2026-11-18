<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionOrangeInOneGameRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'orange_in_one_game';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most orange monsters killed in a single game
        return $this->best($progress, $this->oranges($event));
    }
}
