<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class DrakhanBlackBallsRule extends DrakhanRule
{
    public function achievementKey(): string
    {
        return 'black_balls';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'nb'));
    }
}
