<?php

namespace App\Achievements\Rules\Games\Tubulo;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class TubuloGreenPaintRule extends TubuloRule
{
    public function achievementKey(): string
    {
        return 'green_paint';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $completedLevelCount = count($this->completedLevels($event));
        $paintedGreen = 0;
        foreach (array_slice($this->levelColors($event), 0, $completedLevelCount) as $colors) {
            $paintedGreen += $colors[1] + $colors[2];
        }

        return AchievementRuleResult::increment($progress->current_value, $paintedGreen);
    }
}
