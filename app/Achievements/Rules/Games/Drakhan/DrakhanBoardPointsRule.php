<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class DrakhanBoardPointsRule extends DrakhanRule
{
    public function achievementKey(): string
    {
        return 'board_points';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the points given by the highest board emptied in the run
        return $this->best($progress, $this->boardPoints($event));
    }
}
