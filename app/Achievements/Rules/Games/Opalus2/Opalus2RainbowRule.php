<?php

namespace App\Achievements\Rules\Games\Opalus2;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class Opalus2RainbowRule extends Opalus2Rule
{
    public function achievementKey(): string
    {
        return 'rainbow';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $max = 0;
        foreach ($this->fallenByColor($event) as $turn) {
            $colors = count(array_filter($turn, fn (int $fallenCount): bool => $fallenCount > 0));
            $max = max($max, $colors);
        }

        return AchievementRuleResult::setProgress(max($progress->current_value, $max));
    }
}
