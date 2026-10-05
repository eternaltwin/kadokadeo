<?php

namespace App\Achievements\Rules\Games\ChocoMouche;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ChocoMoucheLevelScoreRule extends ChocoMoucheRule
{
    public function achievementKey(): string
    {
        return 'level_score';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $points = data_get($event->stats, 'p', []);

        return $this->bestProgress($progress->current_value, $points === [] ? 0 : max($points));
    }
}
