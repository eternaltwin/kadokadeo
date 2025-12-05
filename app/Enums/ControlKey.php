<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

enum ControlKey: string implements HasLabel
{
    case MOUSE = 'mouse';
    case MOUSE1 = 'mouse1';
    case MOUSE2 = 'mouse2';
    case SPACE = 'space';
    case ENTER = 'enter';
    case ARROWUP = 'arrowup';
    case ARROWDOWN = 'arrowdown';
    case ARROWLEFT = 'arrowleft';
    case ARROWRIGHT = 'arrowright';
    case A = 'a';
    case B = 'b';
    case C = 'c';
    case D = 'd';
    case E = 'e';
    case F = 'f';
    case G = 'g';
    case H = 'h';
    case I = 'i';
    case J = 'j';
    case K = 'k';
    case L = 'l';
    case M = 'm';
    case N = 'n';
    case O = 'o';
    case P = 'p';
    case Q = 'q';
    case R = 'r';
    case S = 's';
    case T = 't';
    case U = 'u';
    case V = 'v';
    case W = 'w';
    case X = 'x';
    case Y = 'y';
    case Z = 'z';

    public function getLabel(): ?string
    {
        return match ($this) {
            self::MOUSE => 'Souris',
            self::MOUSE1 => 'Clic gauche',
            self::MOUSE2 => 'Clic droit',
            self::SPACE => 'Espace',
            self::ENTER => 'Entrée',
            self::ARROWUP => 'Flèche haut',
            self::ARROWDOWN => 'Flèche bas',
            self::ARROWLEFT => 'Flèche gauche',
            self::ARROWRIGHT => 'Flèche droite',
            self::A => 'A',
            self::B => 'B',
            self::C => 'C',
            self::D => 'D',
            self::E => 'E',
            self::F => 'F',
            self::G => 'G',
            self::H => 'H',
            self::I => 'I',
            self::J => 'J',
            self::K => 'K',
            self::L => 'L',
            self::M => 'M',
            self::N => 'N',
            self::O => 'O',
            self::P => 'P',
            self::Q => 'Q',
            self::R => 'R',
            self::S => 'S',
            self::T => 'T',
            self::U => 'U',
            self::V => 'V',
            self::W => 'W',
            self::X => 'X',
            self::Y => 'Y',
            self::Z => 'Z',
        };
    }
}
