<?php

namespace App\Achievements\Rules\Games\Starfang;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class StarfangRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'starfang') {}

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
        $bonuses = data_get($event->stats, 'b', []);
        $killsByBonus = data_get($event->stats, 'kb', []);
        $levels = data_get($event->stats, 'l', []);

        if (!is_array($bonuses) || !is_array($killsByBonus) || count($killsByBonus) !== 11 || !is_array($levels)) {
            return false;
        }

        foreach ($bonuses as $bonus) {
            if (!is_int($bonus)) {
                return false;
            }
        }

        foreach ($killsByBonus as $killCount) {
            if (!is_int($killCount) || $killCount < 0) {
                return false;
            }
        }

        foreach ($levels as $levelStats) {
            if (!is_array($levelStats) || count($levelStats) !== 7) {
                return false;
            }

            foreach ($levelStats as $stat) {
                if (!is_int($stat) || $stat < 0) {
                    return false;
                }
            }
        }

        return true;
    }

    protected function completedLevels(array $levels): array
    {
        if (count($levels) === 0) {
            return [];
        }

        return array_slice($levels, 0, -1);
    }
}
