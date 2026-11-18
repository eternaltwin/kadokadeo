<?php

namespace App\Achievements\Rules\Games\TwinSpirit;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class TwinSpiritRule extends GameRule
{
    protected const GAME = 'twinspirit';

    // k: enemies killed, v: electric balls killed, mc: best combo, fd: id of the first twin to die in twin mode
    // (-1: none), r: 1 if Robert killed, sf: 1 if Futuna took a bullet aimed at Wallis, ws: score from Wallis's kills
    public function validate(GameRunCompleted $event): bool
    {
        $kills = data_get($event->stats, 'k');
        $volt = data_get($event->stats, 'v');
        $combo = data_get($event->stats, 'mc');
        $firstDeath = data_get($event->stats, 'fd');
        $robert = data_get($event->stats, 'r');
        $shield = data_get($event->stats, 'sf');
        $wallis = data_get($event->stats, 'ws');

        foreach ([$kills, $volt, $combo, $wallis] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        // the twin ids are 0 (Wallis) and 1 (Futuna); -1 when no twin died
        if (!in_array($firstDeath, [-1, 0, 1], true)) {
            return false;
        }

        if (!in_array($robert, [0, 1], true) || !in_array($shield, [0, 1], true)) {
            return false;
        }

        // electric balls are a subset of the enemies killed
        if ($volt > $kills) {
            return false;
        }

        // Wallis's share of the score is part of the run's score
        if ($wallis > $event->run->score) {
            return false;
        }

        return true;
    }
}
