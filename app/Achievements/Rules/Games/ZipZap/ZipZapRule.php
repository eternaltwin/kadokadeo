<?php

namespace App\Achievements\Rules\Games\ZipZap;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class ZipZapRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'zipzap') {}

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
        $combo = data_get($event->stats, 'c', []);
        $clics = data_get($event->stats, 'm', 0);
        $perAction = data_get($event->stats, 'pa', []);
        $blackBalloons = data_get($event->stats, 'bb', []);

        if (!is_int($clics) || !is_array($combo) || count($combo) !== 5 || !is_array($perAction) || count($perAction) !== $clics || !is_array($blackBalloons)) {
            return false;
        }

        foreach ($combo as $pops) {
            if (!is_int($pops) || $pops < 0) {
                return false;
            }
        }

        $perActionTotals = [0, 0, 0, 0, 0];
        $blackPops = 0;

        foreach ($perAction as $action) {
            if (!is_array($action) || count($action) !== 6) {
                return false;
            }

            foreach ($action as $pops) {
                if (!is_int($pops) || $pops < 0) {
                    return false;
                }
            }

            for ($i = 0; $i < 5; $i++) {
                $perActionTotals[$i] += $action[$i];
            }

            $blackPops += $action[5];
        }

        if ($perActionTotals !== array_values($combo) || $blackPops > 1 || $blackPops > count($blackBalloons)) {
            return false;
        }

        foreach ($blackBalloons as $blackBalloon) {
            if (!is_array($blackBalloon) || count($blackBalloon) !== 2) {
                return false;
            }

            [$level, $remainingBalloons] = array_values($blackBalloon);
            if (!is_int($level) || $level < 0 || !is_int($remainingBalloons) || $remainingBalloons < 0) {
                return false;
            }
        }

        return true;
    }
}
