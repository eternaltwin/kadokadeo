<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CrepuscudMachineGunRule extends CrepuscudRule
{
    public function achievementKey(): string
    {
        return 'machine_gun';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // empty the ammo then refill it to the maximum in a single game
        return $this->best($progress, data_get($event->stats, 'mg'));
    }
}
