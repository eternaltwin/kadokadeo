<?php

namespace App\Enums;

// the tournament of the clans lasts a period: missions first, then attacks and defenses (kado.clans.mission_days)
enum ClanPhase: string
{
    case MISSIONS = 'missions';
    case WAR = 'war';

    public function label(): string
    {
        return match ($this) {
            self::MISSIONS => 'Période des missions',
            self::WAR => 'Période offensive',
        };
    }
}
