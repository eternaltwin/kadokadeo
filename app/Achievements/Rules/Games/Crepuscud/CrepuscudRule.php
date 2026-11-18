<?php

namespace App\Achievements\Rules\Games\Crepuscud;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class CrepuscudRule extends GameRule
{
    protected const GAME = 'crepuscud';

    // md: missiles destroyed, mu: munitions fired, me: most missiles destroyed by one wave, gl: missiles that reached the
    // ground, mg: 1 once the ammo went to zero then back to the maximum, rb: 1 once a single wave destroyed a missile of
    // each of the three special colours
    public function validate(GameRunCompleted $event): bool
    {
        $md = data_get($event->stats, 'md');
        $mu = data_get($event->stats, 'mu');
        $me = data_get($event->stats, 'me');
        $gl = data_get($event->stats, 'gl');
        $mg = data_get($event->stats, 'mg');
        $rb = data_get($event->stats, 'rb');

        if (!Stats::isCount($md) || !Stats::isCount($mu) || !Stats::isCount($me) || !Stats::isCount($gl)) {
            return false;
        }

        return in_array($mg, [0, 1], true) && in_array($rb, [0, 1], true);
    }
}
