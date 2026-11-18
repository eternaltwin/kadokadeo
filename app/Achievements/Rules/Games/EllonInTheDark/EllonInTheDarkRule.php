<?php

namespace App\Achievements\Rules\Games\EllonInTheDark;

use App\Achievements\Events\GameRunCompleted;
use App\Achievements\GameRule;
use App\Achievements\Stats;

abstract class EllonInTheDarkRule extends GameRule
{
    protected const GAME = 'elloninthedark';

    // the kills array has one slot per enemy gid; the spider (« araignée ») is the Medusa, gid 8
    private const KILLS = 23;

    private const SPIDER = 8;

    // the secondary upgrades: the bomb (10), tentacle (11) and homing (12) side-weapon bonuses
    private const SECONDARY = [10, 11, 12];

    // the weapons have three power levels; the hero can hold up to five tentacles
    private const MAX_WEAPON_LEVEL = 3;

    private const MAX_TENTACLES = 5;

    // k: kills by gid, b: bonus ids taken, d: difficulty, w: highest blue/violet weapon level, t: most tentacles held at
    // once, g: 1 once hit by a gum ball, h: 1 once a Golgoth was killed by the charged shot
    public function validate(GameRunCompleted $event): bool
    {
        $kills = data_get($event->stats, 'k');
        $bonus = data_get($event->stats, 'b');
        $weapon = data_get($event->stats, 'w');
        $tentacles = data_get($event->stats, 't');
        $gum = data_get($event->stats, 'g');
        $head = data_get($event->stats, 'h');

        if (!Stats::isCounts($kills, self::KILLS) || !Stats::isCounts($bonus)) {
            return false;
        }
        if (!Stats::isCount($weapon) || !Stats::isCount($tentacles)) {
            return false;
        }

        return in_array($gum, [0, 1], true) && in_array($head, [0, 1], true)
            && $weapon <= self::MAX_WEAPON_LEVEL && $tentacles <= self::MAX_TENTACLES;
    }

    // the spiders (Medusa, gid 8) killed in the run
    protected function spiders(GameRunCompleted $event): int
    {
        return data_get($event->stats, 'k')[self::SPIDER];
    }

    // the secondary upgrades (bomb, tentacle, homing bonuses) taken in the run
    protected function secondaryUpgrades(GameRunCompleted $event): int
    {
        return count(array_filter(data_get($event->stats, 'b'), fn (int $id): bool => in_array($id, self::SECONDARY, true)));
    }
}
