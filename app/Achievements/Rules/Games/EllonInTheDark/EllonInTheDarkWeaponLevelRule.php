<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkWeaponLevelRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'weapon_level';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'w'));
    }
}
