<?php

namespace App\Achievements;

use App\Enums\AchievementCategory;
use App\Models\UserAchievementProgress;

interface AchievementRule
{
    public function achievementKey(): string;

    public function category(): AchievementCategory;

    public function gameKey(): ?string;

    public function supports(object $event): bool;

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult;
}
