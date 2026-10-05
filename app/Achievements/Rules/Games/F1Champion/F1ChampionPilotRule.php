<?php

namespace App\Achievements\Rules\Games\F1Champion;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class F1ChampionPilotRule extends F1ChampionRule
{
    private const DISTANCE_UNITS_PER_KM = 25;

    public function achievementKey(): string
    {
        return 'pilot';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $km = min(10, intdiv(data_get($event->stats, 'm', 0), self::DISTANCE_UNITS_PER_KM));

        return AchievementRuleResult::setProgress(max($progress->current_value, $km));
    }
}
