<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class TwinSpiritVoltKillsRule extends TwinSpiritRule
{
    public function achievementKey(): string
    {
        return 'volt_kills';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'v'));
    }
}
