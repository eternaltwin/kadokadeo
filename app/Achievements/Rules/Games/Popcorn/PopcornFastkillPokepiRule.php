<?php

namespace App\Achievements\Rules\Games\Popcorn;

use App\Achievements\AchievementRuleResult;
use App\Models\UserAchievementProgress;

class PopcornFastkillPokepiRule extends PopcornRule
{
    private const ONE_MINUTE_IN_FRAMES = 60 * 32;

    public function achievementKey(): string
    {
        return 'fastkill_pokepi';
    }

    public function evaluate(object $event, UserAchievementProgress $progress): AchievementRuleResult
    {
        if (!$this->validate($event)) {
            return AchievementRuleResult::unchanged($progress->current_value);
        }

        $bossHitFrames = data_get($event->stats, 'bhf', []);
        $fastKill = count($bossHitFrames) === 7 && max($bossHitFrames) < self::ONE_MINUTE_IN_FRAMES;

        return $this->bestProgress($progress->current_value, $fastKill ? 1 : 0);
    }
}
