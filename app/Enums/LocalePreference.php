<?php

namespace App\Enums;

// the language a player chose on his account (users.locale); auto: his browser
enum LocalePreference: string
{
    case AUTO = 'auto';
    case FR = 'fr';
    case EN = 'en';
}
