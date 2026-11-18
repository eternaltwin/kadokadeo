<?php

namespace App\Achievements\Rules\Games\Alchimie;

use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Models\UserAchievementProgress;

class AlchimieLeafRushRule extends AlchimieRule
{
    public function achievementKey(): string
    {
        return 'leaf_rush';
    }

    protected function progress(GameRunCompleted $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        // lf: drops done when the first leaf appeared (-1: none). Reach a leaf in fewer than 10 drops.
        $firstLeaf = data_get($event->stats, 'lf');

        return $this->best($progress, $firstLeaf !== -1 && $firstLeaf < 10 ? 1 : 0);
    }
}
