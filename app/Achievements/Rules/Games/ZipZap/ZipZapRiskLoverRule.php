<?php

namespace App\Achievements\Rules\Games\ZipZap;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class ZipZapRiskLoverRule extends ZipZapRule
{
    public function achievementKey(): string
    {
        return 'risk_lover';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $blackBalloonsPopped = array_sum(array_map(fn ($action) => $action[5], data_get($event->stats, 'pa', [])));
        $riskyBlackBalloons = count(array_filter(data_get($event->stats, 'bb', []), fn ($blackBalloon) => $blackBalloon[1] >= 50));

        if ($blackBalloonsPopped === 0 && $riskyBlackBalloons >= 3) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
