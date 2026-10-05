<?php

namespace App\Achievements\Rules\Games\F1Champion;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class F1ChampionRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'f1champion') {}

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
        $km = data_get($event->stats, 'n', 0);
        $outs = data_get($event->stats, 'o');
        $maxKmWithoutOut = data_get($event->stats, 'm');
        $speedOver230Frames = data_get($event->stats, 'so');
        $life = data_get($event->stats, 'l');

        return is_int($km)
            && $km >= 0
            && is_array($bonuses)
            && count($bonuses) === 5
            && collect($bonuses)->every(fn ($bonus) => is_int($bonus) && $bonus >= 0)
            && is_int($outs)
            && $outs >= 0
            && is_int($maxKmWithoutOut)
            && $maxKmWithoutOut >= 0
            && is_int($speedOver230Frames)
            && $speedOver230Frames >= 0
            && is_array($life)
            && collect($life)->every(fn ($percentage) => is_int($percentage) && $percentage >= 0 && $percentage <= 100);
    }
}
