<?php

namespace App\Achievements\Rules\Games\PiouPiou;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class PiouPiouRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'pioupiou') {}

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
        $bubbles = data_get($event->stats, 'b', []);
        $height = data_get($event->stats, 'l', 0);
        $firstBubbleLevel = data_get($event->stats, 'fbl', 0);
        $fallingBubbles = data_get($event->stats, 'fb', []);
        $bubblePopped = data_get($event->stats, 'bp', []);
        $climbHeight = data_get($event->stats, 'ch', 0);

        if (!$this->isPositiveInteger($height) || !$this->isPositiveInteger($firstBubbleLevel) || !$this->isPositiveInteger($climbHeight)) {
            return false;
        }

        if (!$this->isBubbleCountList($bubbles) || !$this->isBubbleCountList($fallingBubbles) || !$this->isBubbleCountList($bubblePopped)) {
            return false;
        }

        // foreach ($fallingBubbles as $index => $count) {
        //     if ($count > $bubbles[$index]) {
        //         return false;
        //     }
        // }

        return true;
    }

    private function isBubbleCountList(mixed $counts): bool
    {
        if (!is_array($counts) || array_keys($counts) !== [0, 1, 2]) {
            return false;
        }

        foreach ($counts as $count) {
            if (!$this->isPositiveInteger($count)) {
                return false;
            }
        }

        return true;
    }

    private function isPositiveInteger(mixed $value): bool
    {
        return is_int($value) && $value >= 0;
    }
}
