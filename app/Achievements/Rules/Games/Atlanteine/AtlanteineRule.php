<?php

namespace App\Achievements\Rules\Games\Atlanteine;

use App\Achievements\AchievementRule;
use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class AtlanteineRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'atlanteine') {}

    public function category(): AchievementCategory
    {
        return AchievementCategory::GAME;
    }

    public function gameKey(): ?string
    {
        return $this->gameKey;
    }

    public function supports(object $event): bool
    {
        return $event instanceof GameRunCompleted && $event->gameKey() === $this->gameKey;
    }

    public function validate(GameRunCompleted $event): bool
    {
        $levels = data_get($event->stats, 's', []);

        if (!is_array($levels)) {
            return false;
        }

        foreach ($levels as $level) {
            if (!is_array($level) || count($level) !== 8) {
                return false;
            }

            [$boxesInLevel, $ghostsInLevel, $boxesMoved, $ghostsKilledBySelf, $ghostsKilledByBlock, $timesKilledByWater, $movesCount, $hasPushedInLevel] = array_values($level);

            foreach ([$boxesInLevel, $ghostsInLevel, $boxesMoved, $ghostsKilledBySelf, $ghostsKilledByBlock, $timesKilledByWater, $movesCount] as $value) {
                if (!is_int($value) || $value < 0) {
                    return false;
                }
            }

            if ($boxesMoved > $timesKilledByWater + $ghostsKilledBySelf + 1 || $ghostsKilledBySelf + $ghostsKilledByBlock > $ghostsInLevel) {
                return false;
            }

            if (!is_int($hasPushedInLevel) || !in_array($hasPushedInLevel, [0, 1], true)) {
                return false;
            }
        }

        return true;
    }

    protected function levels(GameRunCompleted $event): array
    {
        return data_get($event->stats, 's', []);
    }

    protected function bestProgress(int $currentValue, int $value): AchievementRuleResult
    {
        if ($value <= $currentValue) {
            return AchievementRuleResult::unchanged($currentValue);
        }

        return AchievementRuleResult::setProgress($value);
    }
}
