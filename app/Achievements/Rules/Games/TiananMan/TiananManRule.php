<?php

namespace App\Achievements\Rules\Games\TiananMan;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class TiananManRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'tiananman') {}

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
        $followersCollected = data_get($event->stats, 'fc', []);
        $vehiclesDestroyed = data_get($event->stats, 'vd', []);
        $fevers = data_get($event->stats, 'f', []);
        $followersLost = data_get($event->stats, 'fl', []);
        $lastFollowerScore = data_get($event->stats, 'lfsc', 0);

        if (!is_array($followersCollected) || !is_array($vehiclesDestroyed) || !is_array($fevers) || !is_array($followersLost) || !is_numeric($lastFollowerScore)) {
            return false;
        }

        if (count($vehiclesDestroyed) !== 5 || count($followersLost) > 180 || count($followersLost) <= 0) {
            return false;
        }

        foreach ($vehiclesDestroyed as $vehicleDestroyed) {
            if (!is_numeric($vehicleDestroyed)) {
                return false;
            }
        }

        foreach ($fevers as $feverFrame) {
            if (!is_numeric($feverFrame)) {
                return false;
            }
        }

        foreach ($followersLost as $followerLostFrame) {
            if (!is_numeric($followerLostFrame)) {
                return false;
            }
        }

        $feverStreaks = 0;
        $wasInFever = false;

        foreach ($followersCollected as $followerCollected) {
            if (!is_array($followerCollected) || count($followerCollected) !== 3) {
                return false;
            }

            [$score, $multiplier, $collectedDuringFeverValue] = array_values($followerCollected);

            if (!is_numeric($score) || !is_numeric($multiplier) || !is_numeric($collectedDuringFeverValue)) {
                return false;
            }

            $collectedDuringFever = (int) $collectedDuringFeverValue;

            if (!in_array($collectedDuringFever, [0, 1], true) || (float) $collectedDuringFeverValue !== (float) $collectedDuringFever) {
                return false;
            }

            if ($collectedDuringFever === 1 && !$wasInFever) {
                $feverStreaks++;
            }

            $wasInFever = $collectedDuringFever === 1;
        }

        return $feverStreaks <= count($fevers);
    }
}
