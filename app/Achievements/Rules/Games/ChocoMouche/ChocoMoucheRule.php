<?php

namespace App\Achievements\Rules\Games\ChocoMouche;

use App\Achievements\AchievementRule;
use App\Achievements\AchievementRuleResult;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class ChocoMoucheRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'chocomouche') {}

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
        $discoveries = data_get($event->stats, 'd', []);
        $clicks = data_get($event->stats, 'c', []);
        $points = data_get($event->stats, 'p', []);
        $times = data_get($event->stats, 't', []);

        if (!is_array($discoveries) || !is_array($clicks) || !is_array($points) || !is_array($times)) {
            return false;
        }

        if (count($discoveries) !== count($clicks) || count($points) !== count($times) || count($discoveries) !== count($points) + 1) {
            return false;
        }

        foreach ($discoveries as $level => $levelDiscoveries) {
            if (!is_array($levelDiscoveries) || !is_int($clicks[$level]) || $clicks[$level] < 0) {
                return false;
            }

            foreach ($levelDiscoveries as $discovery) {
                if (!is_int($discovery) || $discovery < -2 || $discovery > 8) {
                    return false;
                }
            }

            if ($level < count($points) && $clicks[$level] === 0) {
                return false;
            }
        }

        foreach ($points as $pointsInLevel) {
            if (!is_int($pointsInLevel) || $pointsInLevel < 0) {
                return false;
            }
        }

        foreach ($times as $timeInLevel) {
            if (!is_int($timeInLevel) || $timeInLevel < 0) {
                return false;
            }
        }

        return true;
    }

    protected function bestProgress(int $currentValue, int $value): AchievementRuleResult
    {
        if ($value <= $currentValue) {
            return AchievementRuleResult::unchanged($currentValue);
        }

        return AchievementRuleResult::setProgress($value);
    }
}
