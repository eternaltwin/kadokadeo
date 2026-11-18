<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionClearBoardRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'clear_board';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // end a game with no monster left on the board
        return $this->best($progress, $this->cleared($event) ? 1 : 0);
    }
}
