<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudMissilesDestroyedRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'missiles_destroyed';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'md'));
    }
}
