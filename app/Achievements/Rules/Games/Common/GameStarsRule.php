<?php

namespace App\Achievements\Rules\Games\Common;

use App\Achievements\AchievementRule;
use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;
use App\Models\UserAchievementProgress;

class GameStarsRule implements AchievementRule
{
    public function achievementKey(): string
    {
        return 'stars';
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
        return $event instanceof GameRunCompleted;
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        $star = $event->game->getStarFromScore($event->run->score);
        if ($star < 0) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        return AchievementRuleResult::setProgress(max($progress->current_value, $star + 1));
    }
}
