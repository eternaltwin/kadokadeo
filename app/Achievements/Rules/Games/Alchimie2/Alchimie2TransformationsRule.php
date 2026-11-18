<?php

namespace App\Achievements\Rules\Games\Alchimie2;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class Alchimie2TransformationsRule extends Alchimie2Rule
{
    public function achievementKey(): string
    {
        return 'transformations';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 't'));
    }
}
