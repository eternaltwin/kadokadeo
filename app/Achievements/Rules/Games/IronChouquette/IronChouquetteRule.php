<?php

namespace App\Achievements\Rules\Games\IronChouquette;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class IronChouquetteRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'ironchouquette') {}

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
        if (!is_array($bonuses)) {
            return false;
        }
        if (!array_all($bonuses, fn ($b) => is_array($b) && count($b) === 2 && is_int($b[0]) && is_int($b[1]) && $b[0] >= 0 && $b[1] >= 0)) {
            return false;
        }
        $kills = data_get($event->stats, 'k', []);
        if (!is_array($kills)) {
            return false;
        }
        if (!array_all($kills, fn ($k) => is_array($k) && count($k) === 2 && is_int($k[0]) && is_int($k[1]) && $k[0] >= 0 && $k[1] >= 0)) {
            return false;
        }
        $specialKills = data_get($event->stats, 'spk', []);
        if (!is_array($specialKills) || count($specialKills) !== 6 || !array_all($specialKills, fn ($k) => is_int($k) && $k >= 0)) {
            return false;
        }
        $sacrificeKills = data_get($event->stats, 'sak', []);
        if (!is_array($sacrificeKills) || count($sacrificeKills) !== 6) {
            return false;
        }
        if (!array_all($sacrificeKills, fn ($sacrifices) => is_array($sacrifices) && array_all($sacrifices, fn ($sacrifice) => is_array($sacrifice) && count($sacrifice) === 2 && is_int($sacrifice[0]) && is_int($sacrifice[1]) && $sacrifice[0] >= 0 && $sacrifice[1] >= 0))) {
            return false;
        }
        $maxEnemyShotCount = data_get($event->stats, 'mesc');
        if (!is_int($maxEnemyShotCount) || $maxEnemyShotCount < 0) {
            return false;
        }
        $waves = data_get($event->stats, 'w', []);
        if (!is_array($waves) || !array_all($waves, fn ($wave) => is_int($wave) && $wave >= 0)) {
            return false;
        }

        return true;
    }

    public function iterateThroughBonuses(GameRunCompleted $event, callable $callback): void
    {
        $bonuses = array_values(data_get($event->stats, 'b', []));

        $bonusSlots = [-1, -1, -1];
        foreach ($bonuses as $index => $bonus) {
            $removedBonus = -1;
            $b = $bonus[1];
            if ($b === 6) {
                $bonusSlots[] = -1;
            } elseif ($b > 99) {
                $nextBonus = $bonuses[$index + 1][1] ?? null;
                $isAutomaticReplacement = !in_array(-1, $bonusSlots, true)
                    && $nextBonus !== null
                    && $nextBonus < 100
                    && $nextBonus !== 6
                    && $bonusSlots[0] === $b - 100;

                // A full inventory removes its first slot before logging the new bonus.
                $pos = false;
                if ($isAutomaticReplacement) {
                    $pos = 0;
                } else {
                    for ($i = count($bonusSlots) - 1; $i >= 0; $i--) {
                        if ($bonusSlots[$i] !== -1) {
                            $pos = $i;
                            break;
                        }
                    }
                }
                if ($pos !== false) {
                    $removedBonus = array_splice($bonusSlots, $pos, 1)[0];
                    $bonusSlots[] = -1;
                }
            } else {
                // find the first slot with -1 and fill it or replace the first slot
                $pos = array_search(-1, $bonusSlots, true);
                if ($pos === false) {
                    $removedBonus = array_splice($bonusSlots, 0, 1)[0];
                    $bonusSlots[] = $b;
                } else {
                    $bonusSlots[$pos] = $b;
                }
            }
            $callback($bonusSlots, $b, $removedBonus);
        }
    }
}
