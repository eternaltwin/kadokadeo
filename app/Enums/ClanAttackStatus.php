<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum ClanAttackStatus: string implements HasLabel
{
    // the score is waiting for a defense
    case ACTIVE = 'active';
    // a defender beat the score: the attack is cancelled
    case REPELLED = 'repelled';
    // not beaten in time: points for the attacker, the same amount taken from the defender
    case WON = 'won';
    // cancelled by the attacker
    case CANCELLED = 'cancelled';

    public function getLabel(): string
    {
        return match ($this) {
            self::ACTIVE => __('server.clans.attack_status.active'),
            self::REPELLED => __('server.clans.attack_status.repelled'),
            self::WON => __('server.clans.attack_status.won'),
            self::CANCELLED => __('server.clans.attack_status.cancelled'),
        };
    }
}
