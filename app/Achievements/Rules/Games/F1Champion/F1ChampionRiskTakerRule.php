<?php

namespace App\Achievements\Rules\Games\F1Champion;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class F1ChampionRiskTakerRule extends F1ChampionRule
{
    public function achievementKey(): string
    {
        return 'risk_taker';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $outs = min(5, data_get($event->stats, 'o', 0));

        return AchievementRuleResult::setProgress(max($progress->current_value, $outs));
    }
}
