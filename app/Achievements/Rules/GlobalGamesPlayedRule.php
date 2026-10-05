<?php

namespace App\Achievements\Rules;

use App\Achievements\AchievementRule;
use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;
use App\Models\UserAchievementProgress;

class GlobalGamesPlayedRule implements AchievementRule
{
    public function achievementKey(): string
    {
        return 'games_played';
    }

    public function category(): AchievementCategory
    {
        return AchievementCategory::GLOBAL;
    }

    public function gameKey(): ?string
    {
        return null;
    }

    public function supports(object $event): bool
    {
        return $event instanceof GameRunCompleted;
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value);
    }
}
