<?php

namespace App\Achievements\Rules\Games\Synapses;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class SynapsesLevelOneScoreRule extends SynapsesRule
{
    public function achievementKey(): string
    {
        return 'level_one_score';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $levelOneConnectedNeurons = data_get($event->stats, 'cn.0', []);

        return AchievementRuleResult::setProgress(max($progress->current_value, array_sum($levelOneConnectedNeurons)));
    }
}
