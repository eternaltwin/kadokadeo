<?php

namespace App\Enums;

use Filament\Support\Contracts\HasColor;
use Filament\Support\Contracts\HasLabel;

enum RunFlagStatus: string implements HasColor, HasLabel
{
    case OPEN = 'open';
    case DISMISSED = 'dismissed';
    case CONFIRMED = 'confirmed';

    public function getLabel(): string
    {
        return match ($this) {
            self::OPEN => 'À examiner',
            self::DISMISSED => 'Classée sans suite',
            self::CONFIRMED => 'Triche confirmée',
        };
    }

    public function getColor(): string
    {
        return match ($this) {
            self::OPEN => 'warning',
            self::DISMISSED => 'gray',
            self::CONFIRMED => 'danger',
        };
    }
}
