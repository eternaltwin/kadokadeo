<?php

namespace App\Achievements\Rules\Games\Invasion;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class InvasionRule extends GameRule
{
    protected const GAME = 'invasion';

    // the three monster kinds: green (0), yellow (1), orange (2, the rarest)
    protected const ORANGE = 2;

    // l: soldiers lost, k: monsters killed by kind, m: monsters left by kind, ak: biggest group of monsters killed in one
    // attack, al: biggest group of soldiers lost in one attack, gc: monster groups (size >= 2) destroyed, ab: most
    // monsters on the border at once, co: soldiers in the four corners at the end, fc: 1 if the last four monsters killed
    // were the four corners, sym: 1 if the full board was ever vertically symmetric
    public function validate(GameRunCompleted $event): bool
    {
        $l = data_get($event->stats, 'l');
        $k = data_get($event->stats, 'k');
        $m = data_get($event->stats, 'm');
        $ak = data_get($event->stats, 'ak');
        $al = data_get($event->stats, 'al');
        $gc = data_get($event->stats, 'gc');
        $ab = data_get($event->stats, 'ab');
        $co = data_get($event->stats, 'co');
        $fc = data_get($event->stats, 'fc');
        $sym = data_get($event->stats, 'sym');

        if (!Stats::isCount($l) || !Stats::isCounts($k, 3) || !Stats::isCounts($m, 3)) {
            return false;
        }
        if (!Stats::isCount($ak) || !Stats::isCount($al) || !Stats::isCount($gc) || !Stats::isCount($ab) || !Stats::isCount($co)) {
            return false;
        }

        return $co <= 4 && in_array($fc, [0, 1], true) && in_array($sym, [0, 1], true);
    }

    // every monster killed in the run, all kinds together
    protected function monstersKilled(GameRunCompleted $event): int
    {
        return array_sum(data_get($event->stats, 'k'));
    }

    // the orange monsters (kind 2) killed in the run
    protected function oranges(GameRunCompleted $event): int
    {
        return data_get($event->stats, 'k')[self::ORANGE];
    }

    // the board was cleared of every monster by the end of the game
    protected function cleared(GameRunCompleted $event): bool
    {
        return array_sum(data_get($event->stats, 'm')) === 0;
    }
}
