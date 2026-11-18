<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudSurgicalStrikeRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'surgical_strike';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // lose a game in which exactly three missiles reached the ground
        return $this->best($progress, data_get($event->stats, 'gl') === 3 ? 1 : 0);
    }
}
