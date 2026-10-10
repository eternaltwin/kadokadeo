<?php

namespace App\Settings;

use Spatie\LaravelSettings\Settings;

// the settings of the clans changed from the admin panel (App\Filament\Pages\ManageClanSettings)
class ClanSettings extends Settings
{
    // the free games of the attacks and defenses given to every player each day (users.clan_attack_games); then the paid
    // clan games. The missions are free and unlimited.
    public int $attack_games_per_day;

    public static function group(): string
    {
        return 'clans';
    }
}
