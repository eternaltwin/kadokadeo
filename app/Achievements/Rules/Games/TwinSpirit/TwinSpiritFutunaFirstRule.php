<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class TwinSpiritFutunaFirstRule extends TwinSpiritRule
{
    public function achievementKey(): string
    {
        return 'futuna_first';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // fd: id of the first twin to die in twin mode; 1 is Futuna
        return $this->best($progress, data_get($event->stats, 'fd') === 1 ? 1 : 0);
    }
}
