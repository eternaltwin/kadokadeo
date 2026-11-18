<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionTripleJackpotRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'triple_jackpot';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most monster groups (two monsters or more) destroyed in a single game
        return $this->best($progress, data_get($event->stats, 'gc'));
    }
}
