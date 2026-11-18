<?php

namespace App\Achievements\Rules\Games\CosmoCrash;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class CosmoCrashRule extends GameRule
{
    protected const GAME = 'cosmocrash';

    // l: shuttles launched in the run, a: astronauts dropped into the shuttles, f: 1 once out of fuel, v: 1 once a
    // shuttle left with a green + blue + rare (type 3) astronaut, e: 1 once a shuttle left full with 8 astronauts
    public function validate(GameRunCompleted $event): bool
    {
        $launches = data_get($event->stats, 'l');
        $astronauts = data_get($event->stats, 'a');
        $fuel = data_get($event->stats, 'f');
        $vip = data_get($event->stats, 'v');
        $full = data_get($event->stats, 'e');

        if (!Stats::isCount($launches) || !Stats::isCount($astronauts)) {
            return false;
        }

        return in_array($fuel, [0, 1], true) && in_array($vip, [0, 1], true) && in_array($full, [0, 1], true);
    }
}
