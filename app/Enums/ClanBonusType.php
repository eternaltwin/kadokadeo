<?php

namespace App\Enums;

use App\Settings\ClanSettings;
use Filament\Support\Contracts\HasLabel;

// the options of the missions (App\Services\ClanMissionService::useBonus): given to every clan at the start of the period
// (App\Settings\ClanSettings::$starting_bonuses), won by chance with the missions (bonus_chance / bonus_weights)
enum ClanBonusType: string implements HasLabel
{
    case MORE_TIME = 'more_time';
    case BAN_GAME = 'ban_game';
    case FORCE_GAME = 'force_game';
    case NEXT_MISSION = 'next_mission';
    case SKIP_STEP = 'skip_step';
    case DOUBLE_POINTS = 'double_points';

    public function getLabel(): string
    {
        return match ($this) {
            self::MORE_TIME => __('server.clans.bonuses.more_time'),
            self::BAN_GAME => __('server.clans.bonuses.ban_game'),
            self::FORCE_GAME => __('server.clans.bonuses.force_game'),
            self::NEXT_MISSION => __('server.clans.bonuses.next_mission'),
            self::SKIP_STEP => __('server.clans.bonuses.skip_step'),
            self::DOUBLE_POINTS => __('server.clans.bonuses.double_points'),
        };
    }

    public function description(): string
    {
        return match ($this) {
            self::MORE_TIME => __('server.clans.bonuses.more_time_description', ['hours' => app(ClanSettings::class)->mission_more_time_hours]),
            self::BAN_GAME => __('server.clans.bonuses.ban_game_description'),
            self::FORCE_GAME => __('server.clans.bonuses.force_game_description'),
            self::NEXT_MISSION => __('server.clans.bonuses.next_mission_description'),
            self::SKIP_STEP => __('server.clans.bonuses.skip_step_description'),
            self::DOUBLE_POINTS => __('server.clans.bonuses.double_points_description'),
        };
    }

    public function icon(): string
    {
        return match ($this) {
            self::MORE_TIME => '/gfx/clan/opt/optMoreTime.gif',
            self::BAN_GAME => '/gfx/clan/opt/optBlacklistGame.gif',
            self::FORCE_GAME => '/gfx/clan/opt/optSelectGame.gif',
            self::NEXT_MISSION => '/gfx/clan/opt/optSkipMission.gif',
            self::SKIP_STEP => '/gfx/clan/opt/optSkipStep.gif',
            self::DOUBLE_POINTS => '/gfx/clan/opt/optDoublePoints.gif',
        };
    }
}
