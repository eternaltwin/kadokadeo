<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class TwinSpiritShipsKilledRule extends TwinSpiritRule
{
    public function achievementKey(): string
    {
        return 'ships_killed';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'k'));
    }
}
