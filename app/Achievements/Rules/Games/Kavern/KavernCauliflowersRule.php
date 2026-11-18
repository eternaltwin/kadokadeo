<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KavernCauliflowersRule extends KavernRule
{
    public function achievementKey(): string
    {
        return 'cauliflowers';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most cauliflowers taken in a single level (the achievement wants two)
        return $this->best($progress, data_get($event->stats, 'cf'));
    }
}
