<?php

namespace App\Achievements\Rules\Games\ToutCaen;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class ToutCaenRule extends GameRule
{
    protected const GAME = 'toutcaen';

    // g: golden fish caught, c: best catch eaten in a single dive, d: dives, sg: 1 once a golden fish is eaten alone,
    // fl: fewest dives used to clear a level >= 10 (-1: none cleared), l1: score earned while on level 1
    public function validate(GameRunCompleted $event): bool
    {
        $gold = data_get($event->stats, 'g');
        $combo = data_get($event->stats, 'c');
        $dives = data_get($event->stats, 'd');
        $solo = data_get($event->stats, 'sg');
        $fast = data_get($event->stats, 'fl');
        $level1 = data_get($event->stats, 'l1');

        foreach ([$gold, $combo, $dives, $level1] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        if (!in_array($solo, [0, 1], true)) {
            return false;
        }

        // fl is -1 (no level >= 10 cleared) or a dive count
        if ($fast !== -1 && !Stats::isCount($fast)) {
            return false;
        }

        // a golden fish eaten alone is a golden fish caught
        if ($solo === 1 && $gold < 1) {
            return false;
        }

        // the dives of one level can't exceed the dives of the whole run
        if ($fast !== -1 && $fast > $dives) {
            return false;
        }

        // the score of level 1 is part of the run's score
        if ($level1 > $event->run->score) {
            return false;
        }

        return true;
    }
}
