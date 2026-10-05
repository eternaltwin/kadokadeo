<?php

namespace App\Achievements\Rules\Games\Synapses;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class SynapsesTotalNeuronsConnectedRule extends SynapsesRule
{
    public function achievementKey(): string
    {
        return 'total_neurons_connected';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $connectedNeurons = data_get($event->stats, 'cn', []);
        $total = array_sum(array_map('count', $connectedNeurons));

        return AchievementRuleResult::increment($progress->current_value, (int) $total);
    }
}
