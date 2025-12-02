<?php
namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum ControlKey: string implements HasLabel
{
    case MOUSE1 = 'mouse1';
    case MOUSE2 = 'mouse2';
    case SPACE = 'space';
    case ENTER = 'enter';
    case ARROWUP = 'arrowup';
    case ARROWDOWN = 'arrowdown';
    case ARROWLEFT = 'arrowleft';
    case ARROWRIGHT = 'arrowright';

    public function getLabel(): ?string
    {
        return match ($this) {
            self::MOUSE1 => 'Clic gauche',
            self::MOUSE2 => 'Clic droit',
            self::SPACE => 'Espace',
            self::ENTER => 'Entrée',
            self::ARROWUP => 'Flèche haut',
            self::ARROWDOWN => 'Flèche bas',
            self::ARROWLEFT => 'Flèche gauche',
            self::ARROWRIGHT => 'Flèche droite',
        };
    }
}
