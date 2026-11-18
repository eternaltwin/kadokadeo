<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudAmmoUsedRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'ammo_used';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'mu'));
    }
}
