<?php

namespace App\Achievements\Rules\Games\Opalus2;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class Opalus2Rule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'opalus2') {}

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
        $turns = data_get($event->stats, 'l', []);
        $fallenByColor = data_get($event->stats, 'f', []);
        $minMax = data_get($event->stats, 'mm', []);

        if (!is_array($turns) || !is_array($fallenByColor) || count($fallenByColor) !== count($turns) || !is_array($minMax) || count($minMax) !== 4) {
            return false;
        }

        foreach ($minMax as $value) {
            if (!is_int($value) || $value < 0 || $value > 14) {
                return false;
            }
        }

        $destroyedTotal = 0;
        $fallenTotal = 0;

        foreach ($turns as $index => $turn) {
            if (!is_array($turn) || count($turn) !== 3) {
                return false;
            }

            [$colorId, $destroyed, $fallen] = array_values($turn);

            if (!is_int($colorId) || $colorId < 0 || $colorId > 6) {
                return false;
            }

            if (!is_int($destroyed) || $destroyed < 0 || $destroyed > 225 || !is_int($fallen) || $fallen < 0 || $fallen > 225) {
                return false;
            }

            $fallenColors = $fallenByColor[$index];
            if (!is_array($fallenColors) || count($fallenColors) !== 7) {
                return false;
            }

            $turnFallenTotal = 0;
            foreach ($fallenColors as $fallenCount) {
                if (!is_int($fallenCount) || $fallenCount < 0 || $fallenCount > 225) {
                    return false;
                }

                $turnFallenTotal += $fallenCount;
            }

            if ($turnFallenTotal !== $fallen) {
                return false;
            }

            $destroyedTotal += $destroyed;
            $fallenTotal += $fallen;

            if ($destroyedTotal > 225 || $fallenTotal > 225) {
                return false;
            }
        }

        return true;
    }

    protected function turns(GameRunCompleted $event): array
    {
        return data_get($event->stats, 'l', []);
    }

    protected function fallenByColor(GameRunCompleted $event): array
    {
        return data_get($event->stats, 'f', []);
    }

    protected function minMax(GameRunCompleted $event): array
    {
        return data_get($event->stats, 'mm', []);
    }
}
