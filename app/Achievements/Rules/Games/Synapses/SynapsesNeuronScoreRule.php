<?php

namespace App\Achievements\Rules\Games\Synapses;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class SynapsesNeuronScoreRule extends SynapsesRule
{
    public function achievementKey(): string
    {
        return 'neuron_score';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $connectedNeurons = data_get($event->stats, 'cn', []);
        $max = 0;
        foreach ($connectedNeurons as $levelConnectedNeurons) {
            if (count($levelConnectedNeurons) > 0) {
                $max = max($max, max($levelConnectedNeurons));
            }
        }

        return AchievementRuleResult::setProgress(max($progress->current_value, $max));
    }
}
