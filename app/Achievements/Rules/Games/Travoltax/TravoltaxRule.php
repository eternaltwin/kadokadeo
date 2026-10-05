<?php

namespace App\Achievements\Rules\Games\Travoltax;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class TravoltaxRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'travoltax') {}

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
        $linesDestroyed = data_get($event->stats, '_l', []);
        $bonuses = data_get($event->stats, '_g', []);
        $opts = data_get($event->stats, '_o', []);
        $contracts = data_get($event->stats, '_c');
        $survivalFrames = data_get($event->stats, '_t');
        $clearCount = data_get($event->stats, '_cc');

        if (!is_array($bonuses) || count($bonuses) !== 3 || !is_array($opts) || !is_array($linesDestroyed)) {
            return false;
        }

        if (!is_array($contracts) || !is_int($survivalFrames) || $survivalFrames < 0 || !is_int($clearCount) || $clearCount < 0) {
            return false;
        }

        foreach ($contracts as $contract) {
            if (!is_int($contract) || $contract < 0 || $contract > 17) {
                return false;
            }
        }

        return true;
    }
}
