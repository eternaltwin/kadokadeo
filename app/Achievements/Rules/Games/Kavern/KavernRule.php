<?php

namespace App\Achievements\Rules\Games\Kavern;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class KavernRule extends GameRule
{
    protected const GAME = 'kavern';

    // the bonus types (kavern.Game.getBonus): b[0], b[1] are energies (life), b[2..7] vegetables, b[7] the cauliflower
    private const BONUS_TYPES = 8;

    // b: bonus taken by type, l: levels crossed, d: depth in meters (only grows), k: rocks broken, c: dig actions,
    // o: 1 once the oxygen gauge was filled to the max, cf: most cauliflowers taken in a single level
    public function validate(GameRunCompleted $event): bool
    {
        $bonus = data_get($event->stats, 'b');
        $levels = data_get($event->stats, 'l');
        $depth = data_get($event->stats, 'd');
        $rocks = data_get($event->stats, 'k');
        $digs = data_get($event->stats, 'c');
        $oxygen = data_get($event->stats, 'o');
        $cauliflowers = data_get($event->stats, 'cf');

        if (!Stats::isCounts($bonus, self::BONUS_TYPES)) {
            return false;
        }
        foreach ([$levels, $depth, $rocks, $digs, $cauliflowers] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        // the cauliflower is the last vegetable (b[7]): never more of them in one level than in the whole run
        return in_array($oxygen, [0, 1], true) && $cauliflowers <= $bonus[7];
    }

    // the vegetables taken: b[2..7]
    protected function legumes(GameRunCompleted $event): int
    {
        return array_sum(array_slice(data_get($event->stats, 'b'), 2));
    }

    // the energies taken: b[0] + b[1]
    protected function energies(GameRunCompleted $event): int
    {
        $bonus = data_get($event->stats, 'b');

        return $bonus[0] + $bonus[1];
    }
}
