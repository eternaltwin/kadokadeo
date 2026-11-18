<?php

namespace App\Achievements\Rules\Games\KanjisAdventure;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KanjisAdventureBearPawsRule extends KanjisAdventureRule
{
    public function achievementKey(): string
    {
        return 'bear_paws';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most bear paws held at once (the achievement wants two)
        return $this->best($progress, data_get($event->stats, 'bp'));
    }
}
