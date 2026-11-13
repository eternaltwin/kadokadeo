<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

// the seats of the attacks and defenses, given by the leader or a right hand (App\Settings\ClanSettings: seats by size of the
// clan). The members without a seat have one attack at a time and can't defend while they attack.
enum ClanCombatRole: string implements HasLabel
{
    // two attacks at the same time
    case ATTACKER = 'attacker';
    // can defend while he attacks
    case DEFENDER = 'defender';

    public function getLabel(): string
    {
        return match ($this) {
            self::ATTACKER => __('server.clans.combat_roles.attacker'),
            self::DEFENDER => __('server.clans.combat_roles.defender'),
        };
    }

    public function description(): string
    {
        return match ($this) {
            self::ATTACKER => __('server.clans.combat_roles.attacker_description'),
            self::DEFENDER => __('server.clans.combat_roles.defender_description'),
        };
    }
}
