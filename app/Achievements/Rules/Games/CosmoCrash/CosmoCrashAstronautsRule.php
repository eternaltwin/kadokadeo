<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class CosmoCrashAstronautsRule extends CosmoCrashRule
{
    public function achievementKey(): string
    {
        return 'total_astronauts';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'a'));
    }
}
