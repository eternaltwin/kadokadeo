<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudRainbowRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'rainbow';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // destroy a missile of each of the three special colours with a single wave
        return $this->best($progress, data_get($event->stats, 'rb'));
    }
}
