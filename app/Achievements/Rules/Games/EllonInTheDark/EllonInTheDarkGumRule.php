<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkGumRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'gum';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // get hit by a gum ball
        return $this->best($progress, data_get($event->stats, 'g'));
    }
}
