<?php

namespace App\Achievements\Rules\Games\Kaskade2;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class Kaskade2Rule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'kaskade2') {}

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
        $pops = data_get($event->stats, 'g', []);
        $time = data_get($event->stats, 't', []);
        $clicks = data_get($event->stats, 'd', []);

        $valid = is_array($pops) && count($pops) === 20
            && is_array($time) && count($time) === 20
            && is_array($clicks) && count($clicks) === 20;

        if (!$valid) {
            return false;
        }

        foreach ($pops as $pop) {
            if (!is_numeric($pop) || $pop < 0 || $pop > 64) {
                return false;
            }
        }

        foreach ($clicks as $click) {
            if (!is_array($click) || count($click) !== 3) {
                return false;
            }

            [$x, $y, $color] = array_values($click);
            if (!is_int($x) || $x < 0 || $x > 7
                || !is_int($y) || $y < 0 || $y > 7
                || !is_int($color) || $color < 0 || $color > 2) {
                return false;
            }
        }

        return true;
    }

    protected function clicks(GameRunCompleted $event): array
    {
        return data_get($event->stats, 'd', []);
    }
}
