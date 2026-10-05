<?php

namespace App\Achievements\Rules\Games\Common;

use App\Achievements\AchievementRule;
use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\LeagueChanged;
use App\Enums\AchievementCategory;
use App\Models\UserAchievementProgress;

class GameParadiseLeagueRule implements AchievementRule
{
    public function achievementKey(): string
    {
        return 'paradise_league';
    }

    public function category(): AchievementCategory
    {
        return AchievementCategory::GAME;
    }

    public function gameKey(): ?string
    {
        return null;
    }

    public function supports(object $event): bool
    {
        return $event instanceof LeagueChanged && $event->toLeague->level === 5;
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::setProgress(max($progress->current_value, 1));
    }
}
