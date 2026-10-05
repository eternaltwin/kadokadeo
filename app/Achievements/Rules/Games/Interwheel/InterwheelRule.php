<?php

namespace App\Achievements\Rules\Games\Interwheel;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class InterwheelRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'interwheel') {}

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
        $height = data_get($event->stats, 'hm', 0);
        $jumps = data_get($event->stats, 'jp', 0);
        $dives = data_get($event->stats, 'pl', 0);
        $pastilles = data_get($event->stats, 'b', []);
        $wheelStats = data_get($event->stats, 'ws', []);
        $maxFallHeight = data_get($event->stats, 'mfh', 0);
        $waterScore = data_get($event->stats, 'was', 0);

        return is_numeric($height)
            && is_numeric($jumps)
            && is_numeric($dives)
            && is_array($pastilles)
            && is_array($wheelStats)
            && is_numeric($maxFallHeight)
            && is_numeric($waterScore)
            && $height >= 0
            && $jumps >= 0
            && $dives >= 0
            && $maxFallHeight >= 0
            && $waterScore >= 0
            && $this->validateWheelStats($wheelStats);
    }

    protected function validateWheelStats(array $wheelStats): bool
    {
        foreach ($wheelStats as $wheel) {
            if (!is_array($wheel) || count($wheel) !== 2) {
                return false;
            }

            [$wheelId, $mines] = array_values($wheel);
            if (!is_int($wheelId) || !is_int($mines) || $wheelId < -1 || $wheelId > 98 || $mines < 0) {
                return false;
            }
        }

        return true;
    }

    protected function dodgedMines(array $wheelStats): int
    {
        return array_sum(array_map(fn (array $wheel): int => $wheel[1], $wheelStats));
    }
}
