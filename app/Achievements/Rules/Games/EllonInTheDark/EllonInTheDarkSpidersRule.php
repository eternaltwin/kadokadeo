<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class EllonInTheDarkSpidersRule extends EllonInTheDarkRule
{
    public function achievementKey(): string
    {
        return 'spiders';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        return AchievementRuleResult::increment($progress->current_value, $this->spiders($event));
    }
}
