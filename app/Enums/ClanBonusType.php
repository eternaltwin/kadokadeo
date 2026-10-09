<?php

namespace App\Enums;

use Filament\Support\Contracts\HasLabel;

// the options a clan wins with its missions (App\Services\ClanService::useBonus), names of the original help
enum ClanBonusType: string implements HasLabel
{
    // mission phase
    case NEXT_MISSION = 'next_mission';
    case DOUBLE_POINTS = 'double_points';
    case BAN_GAME = 'ban_game';
    case FORCE_GAME = 'force_game';
    case MORE_TIME = 'more_time';
    case SKIP_STEP = 'skip_step';
    // war phase: the leader can give them to a member
    case DOUBLE_ATTACK = 'double_attack';
    case SUPER_DEFENSE = 'super_defense';

    public function getLabel(): string
    {
        return match ($this) {
            self::NEXT_MISSION => 'Mission suivante',
            self::DOUBLE_POINTS => 'Double points',
            self::BAN_GAME => 'Jeu caca',
            self::FORCE_GAME => 'Jeu cool',
            self::MORE_TIME => 'Plus de temps',
            self::SKIP_STEP => 'Passe étape',
            self::DOUBLE_ATTACK => 'Double attaque',
            self::SUPER_DEFENSE => 'Défense 120%',
        };
    }

    public function description(): string
    {
        return match ($this) {
            self::NEXT_MISSION => 'Annule la mission en cours et génère une nouvelle mission. Les étapes réussies de la mission annulée ne rapportent pas de point.',
            self::DOUBLE_POINTS => 'La prochaine mission rapportera deux fois plus de points à votre clan si vous la terminez.',
            self::BAN_GAME => 'Sélectionne un jeu qui ne sera jamais présent dans les futures missions de la période.',
            self::FORCE_GAME => 'Sélectionne un jeu qui sera obligatoirement présent dans toutes les futures missions de la période.',
            self::MORE_TIME => 'Ajoute 6 heures à la mission en cours pour pouvoir la finir.',
            self::SKIP_STEP => 'Supprime une étape au choix de votre mission.',
            self::DOUBLE_ATTACK => 'Permet à un joueur de lancer une seconde attaque en parallèle.',
            self::SUPER_DEFENSE => 'Le score d\'une défense compte pour 120% (seulement pour la défense, pas pour les records).',
        };
    }

    public function icon(): string
    {
        return match ($this) {
            self::NEXT_MISSION => '/gfx/clan/opt/optSkipMission.gif',
            self::DOUBLE_POINTS => '/gfx/clan/opt/optDoublePoints.gif',
            self::BAN_GAME => '/gfx/clan/opt/optBlacklistGame.gif',
            self::FORCE_GAME => '/gfx/clan/opt/optSelectGame.gif',
            self::MORE_TIME => '/gfx/clan/opt/optMoreTime.gif',
            self::SKIP_STEP => '/gfx/clan/opt/optSkipStep.gif',
            self::DOUBLE_ATTACK => '/gfx/clan/opt/optDoubleAttack.gif',
            self::SUPER_DEFENSE => '/gfx/clan/opt/optSuperDefense.gif',
        };
    }

    public function phase(): ClanPhase
    {
        return match ($this) {
            self::DOUBLE_ATTACK, self::SUPER_DEFENSE => ClanPhase::WAR,
            default => ClanPhase::MISSIONS,
        };
    }

    // the only two options the leader can give to a member, who uses it himself
    public function isAssignable(): bool
    {
        return $this->phase() === ClanPhase::WAR;
    }
}
