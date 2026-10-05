<?php

namespace App\Enums;

use Filament\Support\Contracts\HasColor;
use Filament\Support\Contracts\HasLabel;

// the replay of a run played again on the server (App\Jobs\VerifyRunReplay)
enum RunVerification: string implements HasColor, HasLabel
{
    case PENDING = 'pending';
    case VERIFIED = 'verified';
    // the replay ends with another score: the score was forged
    case MISMATCH = 'mismatch';
    // a finished run always sends a valid replay: without one, the score was forged
    case NO_REPLAY = 'no_replay';
    // the verifier could not play the replay (crash, timeout): to look at
    case FAILED = 'failed';

    public function getLabel(): string
    {
        return match ($this) {
            self::PENDING => 'En attente',
            self::VERIFIED => 'Vérifiée',
            self::MISMATCH => 'Score différent',
            self::NO_REPLAY => 'Sans replay valide',
            self::FAILED => 'Échec de la vérification',
        };
    }

    public function getColor(): string
    {
        return match ($this) {
            self::PENDING => 'gray',
            self::VERIFIED => 'success',
            self::MISMATCH, self::NO_REPLAY => 'danger',
            self::FAILED => 'warning',
        };
    }
}
