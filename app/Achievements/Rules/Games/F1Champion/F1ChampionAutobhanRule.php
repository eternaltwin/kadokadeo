<?php

namespace App\Achievements\Rules\Games\F1Champion;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class F1ChampionAutobhanRule extends F1ChampionRule
{
    private const FRAMES_PER_SECOND = 32;

    public function achievementKey(): string
    {
        return 'autobhan';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $seconds = min(20, intdiv(data_get($event->stats, 'so', 0), self::FRAMES_PER_SECOND));

        return AchievementRuleResult::setProgress(max($progress->current_value, $seconds));
    }
}
