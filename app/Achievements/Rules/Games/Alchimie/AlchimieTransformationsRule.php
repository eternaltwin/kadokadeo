<?php

namespace App\Achievements\Rules\Games\Alchimie;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class AlchimieTransformationsRule extends AlchimieRule
{
    public function achievementKey(): string
    {
        return 'transformations';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'tr'));
    }
}
