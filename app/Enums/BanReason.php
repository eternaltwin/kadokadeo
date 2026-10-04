<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum BanReason: string implements HasLabel
{
    case CHEAT = 'cheat';
    case MULTI_ACCOUNT = 'multi_account';

    public function getLabel(): string
    {
        return match ($this) {
            self::CHEAT => 'Tricherie',
            self::MULTI_ACCOUNT => 'Multicompte',
        };
    }

    // shown to the player when they try to log in or use the site
    public function message(): string
    {
        return match ($this) {
            self::CHEAT => 'Votre compte a été banni pour tricherie.',
            self::MULTI_ACCOUNT => 'Votre compte a été banni pour multicompte.',
        };
    }
}
