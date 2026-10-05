<?php

namespace App\Achievements\Rules\Games\Travoltax;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TravoltaxMafiaRule extends TravoltaxRule
{
    private const MINIMUM_EIGHT_THOUSAND_POINTS_CONTRACT = 14;

    public function achievementKey(): string
    {
        return 'mafia';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $contracts = data_get($event->stats, '_c');
        foreach ($contracts as $contract) {
            if ($contract >= self::MINIMUM_EIGHT_THOUSAND_POINTS_CONTRACT) {
                return AchievementRuleResult::setProgress(1);
            }
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
