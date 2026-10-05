<?php

namespace App\Achievements\Rules\Games\Synapses;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class SynapsesChampionRule extends SynapsesRule
{
    public function achievementKey(): string
    {
        return 'champion';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        foreach (data_get($event->stats, 'ls', []) as $levelStats) {
            if (count($levelStats['es']) === 5 && $this->playerWinsLevel($levelStats['es'])) {
                return AchievementRuleResult::setProgress(max($progress->current_value, $levelStats['es'][0]));
            }
        }

        return AchievementRuleResult::unchanged($progress->current_value);
    }
}
