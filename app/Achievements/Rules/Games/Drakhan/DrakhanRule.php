<?php

namespace App\Achievements\Rules\Games\Drakhan;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class DrakhanRule extends GameRule
{
    protected const GAME = 'drakhan';

    // the points a cleared board gives: the n-th board emptied gives 2000 * n (drakhan.Game.newTurn)
    private const BOARD_POINTS = 2000;

    // s: boards emptied, mc: highest combo reached, nb: black (mu) balls dropped, gb: most black balls dropped at once,
    // nv: 1 once a frozen navy ball was placed
    public function validate(GameRunCompleted $event): bool
    {
        $boards = data_get($event->stats, 's');
        $combo = data_get($event->stats, 'mc');
        $black = data_get($event->stats, 'nb');
        $group = data_get($event->stats, 'gb');
        $navy = data_get($event->stats, 'nv');

        foreach ([$boards, $combo, $black, $group] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        // a single drop can't hold more black balls than the run dropped in all
        return in_array($navy, [0, 1], true) && $group <= $black;
    }

    // the points of the highest board reached: the s-th board emptied gives 2000 * s
    protected function boardPoints(GameRunCompleted $event): int
    {
        return self::BOARD_POINTS * data_get($event->stats, 's');
    }
}
