<?php

namespace App\Achievements\Rules\Games\KanjisAdventure;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KanjisAdventureFoodRule extends KanjisAdventureRule
{
    public function achievementKey(): string
    {
        return 'food';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most food held at once (the achievement wants 1.000)
        return $this->best($progress, data_get($event->stats, 'mf'));
    }
}
