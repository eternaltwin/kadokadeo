<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class TwinSpiritShieldFutunaRule extends TwinSpiritRule
{
    public function achievementKey(): string
    {
        return 'shield_futuna';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return $this->best($progress, data_get($event->stats, 'sf'));
    }
}
