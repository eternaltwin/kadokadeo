<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkSecondaryUpgradesRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'secondary_upgrades';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, $this->secondaryUpgrades($event));
    }
}
