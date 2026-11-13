<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

// the rank of a member in his clan: the leader (a single one, clans.leader_id) can do everything, a right hand everything
// but disband the clan (App\Services\ClanService::assertManager)
enum ClanRole: string implements HasLabel
{
    case LEADER = 'leader';
    case RIGHT_HAND = 'right_hand';
    case MEMBER = 'member';

    // (a locale for a text written for another player)
    public function getLabel(?string $locale = null): string
    {
        return match ($this) {
            self::LEADER => __('server.clans.roles.leader', [], $locale),
            self::RIGHT_HAND => __('server.clans.roles.right_hand', [], $locale),
            self::MEMBER => __('server.clans.roles.member', [], $locale),
        };
    }

    public function canManage(): bool
    {
        return $this !== self::MEMBER;
    }
}
