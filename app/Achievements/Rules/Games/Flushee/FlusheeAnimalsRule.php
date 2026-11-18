<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class FlusheeAnimalsRule extends FlusheeRule
{
    public function achievementKey(): string
    {
        return 'total_animals_eliminated';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'a'));
    }
}
