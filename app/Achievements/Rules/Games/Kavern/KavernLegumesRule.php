<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class KavernLegumesRule extends KavernRule
{
    public function achievementKey(): string
    {
        return 'legumes';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, $this->legumes($event));
    }
}
