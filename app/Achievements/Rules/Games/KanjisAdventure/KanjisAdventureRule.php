<?php

namespace App\Achievements\Rules\Games\KanjisAdventure;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class KanjisAdventureRule extends GameRule
{
    protected const GAME = 'kanjisadventure';

    // the scroll types of the game (Pr. Feu, Pr. Glace, Pr. Teleport., Pr. Chaos)
    private const SCROLL_TYPES = 4;

    // wk: witches (the sorcerer, bid 7) killed, st: steps walked, gs: gold spent at the trader, mf: most food held at
    // once, s4: most distinct scroll types in the bag at once, bp: most bear paws (lucky paw, item 24) in the bag at once
    public function validate(GameRunCompleted $event): bool
    {
        $witches = data_get($event->stats, 'wk');
        $steps = data_get($event->stats, 'st');
        $gold = data_get($event->stats, 'gs');
        $food = data_get($event->stats, 'mf');
        $scrolls = data_get($event->stats, 's4');
        $paws = data_get($event->stats, 'bp');

        foreach ([$witches, $steps, $gold, $food, $scrolls, $paws] as $count) {
            if (!Stats::isCount($count)) {
                return false;
            }
        }

        // there are only four scroll types, so never more than four in the bag at once
        return $scrolls <= self::SCROLL_TYPES;
    }
}
