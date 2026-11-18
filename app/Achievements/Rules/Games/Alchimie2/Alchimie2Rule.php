<?php

namespace App\Achievements\Rules\Games\Alchimie2;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class Alchimie2Rule extends GameRule
{
    protected const GAME = 'alchimie2';

    // t: groups transmuted, c: parasite blocks (cailloux) destroyed, d: dynamites used, f: 1 if an Alchimoth (fly) is
    // used, g: 1 if a gold element (pépite) is produced, ro: 1 if a parasite overflows the limit line at game over
    public function validate(GameRunCompleted $event): bool
    {
        $transforms = data_get($event->stats, 't');
        $rocks = data_get($event->stats, 'c');
        $dynamites = data_get($event->stats, 'd');
        $fly = data_get($event->stats, 'f');
        $gold = data_get($event->stats, 'g');
        $overflow = data_get($event->stats, 'ro');

        foreach ([$transforms, $rocks, $dynamites] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        foreach ([$fly, $gold, $overflow] as $flag) {
            if (!in_array($flag, [0, 1], true)) {
                return false;
            }
        }

        return true;
    }
}
