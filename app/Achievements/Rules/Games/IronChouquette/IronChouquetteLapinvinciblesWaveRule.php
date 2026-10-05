<?php

namespace App\Achievements\Rules\Games\IronChouquette;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class IronChouquetteLapinvinciblesWaveRule extends IronChouquetteRule
{
    public function achievementKey(): string
    {
        return 'lapinvincibles_wave';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }
        $waves = data_get($event->stats, 'w', []);
        $indexOf34 = array_search(34, $waves);

        if ($indexOf34 !== false && $indexOf34 < count($waves) - 2) {
            return AchievementRuleResult::setProgress(1);
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
