<?php

namespace App\Filament\Concerns;

trait WarnsWhenAchievementsDisabled
{
    protected static function achievementsDisabledNotice(): ?string
    {
        if (config('kado.achievements.enabled')) {
            return null;
        }

        return '⚠️ Les succès sont désactivés globalement (KADO_ACHIEVEMENTS_ENABLED) : aucune progression n\'est calculée et rien n\'est affiché aux joueurs.';
    }
}
