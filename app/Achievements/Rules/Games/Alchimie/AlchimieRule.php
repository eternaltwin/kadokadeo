<?php

namespace App\Achievements\Rules\Games\Alchimie;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class AlchimieRule extends GameRule
{
    protected const GAME = 'alchimie';

    // tr: groups transmuted, ch: best cascade (explosion waves) in the run, pi: owls (id 10) produced, lf: drops done
    // when the first leaf (id 4) appeared (-1: none), fs: 1 if the board holds only basic flasks at game over, pe: 1 if
    // a gold nugget (id 11) was produced
    public function validate(GameRunCompleted $event): bool
    {
        $transforms = data_get($event->stats, 'tr');
        $chain = data_get($event->stats, 'ch');
        $pious = data_get($event->stats, 'pi');
        $firstLeaf = data_get($event->stats, 'lf');
        $flasks = data_get($event->stats, 'fs');
        $gold = data_get($event->stats, 'pe');

        foreach ([$transforms, $chain, $pious] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        // lf is -1 (no leaf produced) or a drop count
        if ($firstLeaf !== -1 && !Stats::isCount($firstLeaf)) {
            return false;
        }

        if (!in_array($flasks, [0, 1], true) || !in_array($gold, [0, 1], true)) {
            return false;
        }

        // every owl is a transmutation
        if ($pious > $transforms) {
            return false;
        }

        // a gold nugget is made from three owls, each produced earlier
        if ($gold === 1 && $pious < 3) {
            return false;
        }

        return true;
    }
}
