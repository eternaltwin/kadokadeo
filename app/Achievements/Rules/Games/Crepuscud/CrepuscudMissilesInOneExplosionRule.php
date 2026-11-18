<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudMissilesInOneExplosionRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'missiles_in_one_explosion';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // the most missiles destroyed by a single wave
        return $this->best($progress, data_get($event->stats, 'me'));
    }
}
