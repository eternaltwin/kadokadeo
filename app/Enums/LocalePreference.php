<?php

namespace App\Enums;

// the language a player chose on his account (users.locale); auto: his browser
enum LocalePreference: string
{
    case AUTO = 'auto';
    case FR = 'fr';
    case EN = 'en';

    /** @return list<self> the languages of the site */
    public static function languages(): array
    {
        return array_values(array_filter(self::cases(), fn (self $preference) => $preference !== self::AUTO));
    }

    // the admin panel is in French
    public function frenchName(): string
    {
        return match ($this) {
            self::AUTO => 'automatique',
            self::FR => 'français',
            self::EN => 'anglais',
        };
    }
}
