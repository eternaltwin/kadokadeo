<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class InvasionScoreWithoutOrangeRule extends InvasionRule
{
    public function achievementKey(): string
    {
        return 'score_without_orange';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the best score of a game where no orange monster was killed
        if ($this->oranges($event) > 0) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return $this->best($progress, $event->run->score);
    }
}
