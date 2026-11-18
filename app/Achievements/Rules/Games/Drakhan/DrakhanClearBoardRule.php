<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class DrakhanClearBoardRule extends DrakhanRule
{
    public function achievementKey(): string
    {
        return 'clear_board';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // empty at least one board
        return $this->best($progress, min(1, data_get($event->stats, 's')));
    }
}
