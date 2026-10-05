<?php

namespace App\Achievements\Rules\Games\KillBulle;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class KillBulleRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'killbulle') {}

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
        $pops = data_get($event->stats, 's', 0);
        $poppedSizes = data_get($event->stats, 'p', []);
        $bonusPops = data_get($event->stats, 'bp', []);

        if (!is_int($pops) || $pops < 0 || !is_array($bonuses) || count($bonuses) !== 4 || !is_array($poppedSizes) || count($poppedSizes) !== $pops || !is_array($bonusPops) || count($bonusPops) !== 4) {
            return false;
        }

        foreach ($bonuses as $bonus) {
            if (!is_int($bonus) || $bonus < 0) {
                return false;
            }
        }

        foreach ($poppedSizes as $size) {
            if (!in_array($size, [12, 25, 50, 100, 150], true)) {
                return false;
            }
        }

        for ($bonusId = 0; $bonusId < 4; $bonusId++) {
            $popsByPickup = $bonusPops[$bonusId] ?? null;

            if (!is_array($popsByPickup)) {
                return false;
            }

            if ($bonusId < 3 && count($popsByPickup) !== $bonuses[$bonusId]) {
                return false;
            }

            if ($bonusId === 3 && count($popsByPickup) !== 0) {
                return false;
            }

            foreach ($popsByPickup as $bonusPop) {
                if (!is_int($bonusPop) || $bonusPop < 0) {
                    return false;
                }
            }
        }

        return true;
    }
}
