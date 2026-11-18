<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkChargedHeadRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'charged_head';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // kill a big green head (Golgoth) with the charged shot
        return $this->best($progress, data_get($event->stats, 'h'));
    }
}
