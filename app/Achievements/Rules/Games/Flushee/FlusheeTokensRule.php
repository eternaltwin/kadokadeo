<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class FlusheeTokensRule extends FlusheeRule
{
    public function achievementKey(): string
    {
        return 'total_tokens_grabbed';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, data_get($event->stats, 'tk'));
    }
}
