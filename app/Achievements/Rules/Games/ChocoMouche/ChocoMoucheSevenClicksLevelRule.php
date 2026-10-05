<?php

namespace App\Achievements\Rules\Games\ChocoMouche;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ChocoMoucheSevenClicksLevelRule extends ChocoMoucheRule
{
    public function achievementKey(): string
    {
        return 'seven_clicks_level';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $clicks = data_get($event->stats, 'c', []);
        $completedLevels = count(data_get($event->stats, 'p', []));

        for ($level = 0; $level < $completedLevels; $level++) {
            if ($clicks[$level] <= 7) {
                return $this->bestProgress($progress->current_value, 1);
            }
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
