<?php

namespace App\Achievements\Rules\Games\KanjisAdventure;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KanjisAdventureScrollsRule extends KanjisAdventureRule
{
    public function achievementKey(): string
    {
        return 'scrolls';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most distinct scroll types held at once (the achievement wants all four)
        return $this->best($progress, data_get($event->stats, 's4'));
    }
}
