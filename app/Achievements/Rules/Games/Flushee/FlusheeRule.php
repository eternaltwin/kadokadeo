<?php

namespace App\Achievements\Rules\Games\Flushee;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class FlusheeRule extends GameRule
{
    protected const GAME = 'flushee';

    // the game already sent n (moves played), s (combo points of each move) and t (cascade turns of each move). The
    // achievements add: a total animals exploded, tk big token gems grabbed, vi most violet animals on the board at
    // once, po most apples (bonus gems) on a single row, bg biggest group exploded in one move
    public function validate(GameRunCompleted $event): bool
    {
        $n = data_get($event->stats, 'n');
        $s = data_get($event->stats, 's');
        $t = data_get($event->stats, 't');
        $animals = data_get($event->stats, 'a');
        $tokens = data_get($event->stats, 'tk');
        $violet = data_get($event->stats, 'vi');
        $apples = data_get($event->stats, 'po');
        $group = data_get($event->stats, 'bg');

        if (!Stats::isCount($n) || !Stats::isCounts($s) || !Stats::isCounts($t) || count($s) !== count($t)) {
            return false;
        }
        if (!Stats::isCount($animals) || !Stats::isCount($tokens)) {
            return false;
        }

        return Stats::isCount($violet) && Stats::isCount($apples) && Stats::isCount($group);
    }

    // the best combo points scored on a single move
    protected function bestCombo(GameRunCompleted $event): int
    {
        $scores = data_get($event->stats, 's');

        return $scores ? max($scores) : 0;
    }
}
