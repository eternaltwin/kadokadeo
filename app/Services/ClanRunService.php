<?php

namespace App\Services;

use App\Enums\ClanActionType;
use App\Enums\ClanAttackStatus;
use App\Exceptions\ClanException;
use App\Models\ClanAction;
use App\Models\ClanAttack;
use App\Models\Run;
use App\Models\User;

// a clan run is a normal run (contract, rankings): the player asks for it on the clan pages (ClanAction), then the next
// run he begins on the game is bound to it, and its score is used when it ends. A mission step is free and unlimited, an
// attack or a defense costs one of the attack games of the day (App\Settings\ClanSettings), then a paid clan game
// (RunController::begin). The games of the day of the normal runs are not used.
class ClanRunService
{
    public function __construct(
        private readonly ClanWarService $warService,
        private readonly ClanMissionService $missionService,
    ) {}

    // "Rejouer" on the page of a clan run: the same clan run again while its target is open (the step not completed yet,
    // the attack still waiting for a defense: improved by the new run), null when the next run would be a normal one
    public function again(ClanAction $action): ?ClanAction
    {
        if ($action->completed_at === null) {
            return null;
        }
        $user = $action->user;

        try {
            return match ($action->type) {
                ClanActionType::MISSION => $this->missionService->startStep($user, $action->missionStep),
                ClanActionType::DEFENSE => $this->warService->startDefense($user, $action->attack),
                ClanActionType::ATTACK => ($attack = $action->attack ?? ClanAttack::query()->where('run_id', $action->run_id)->first())
                    && $attack->status === ClanAttackStatus::ACTIVE
                    ? $this->warService->startImprovement($user, $attack)
                    : null,
            };
        } catch (ClanException) {
            return null;
        }
    }

    // the clan run asked by the player on this game, not begun yet
    public function pendingAction(int $userId, int $gameId): ?ClanAction
    {
        return ClanAction::query()
            ->where('user_id', $userId)
            ->where('game_id', $gameId)
            ->whereNull('run_id')
            ->whereNull('completed_at')
            ->where('created_at', '>=', now()->subMinutes(ClanWarService::ACTION_TTL_MINUTES))
            ->latest('id')
            ->first();
    }

    // a mission step
    public const COST_FREE = 'free';

    // a normal run: a game of the day
    public const COST_GAME = 'game';

    // an attack or a defense: an attack game of the day, else a paid clan game
    public const COST_CLAN = 'clan';

    public function runCost(?ClanAction $action): string
    {
        return match ($action?->type) {
            ClanActionType::MISSION => self::COST_FREE,
            ClanActionType::ATTACK, ClanActionType::DEFENSE => self::COST_CLAN,
            null => self::COST_GAME,
        };
    }

    public function hasClanGame(User $user): bool
    {
        return $user->clan_attack_games > 0 || $user->clan_games > 0;
    }

    // an attack game of the day, else a paid clan game; false when there is none left
    public function useClanGame(User $user): bool
    {
        return User::query()->whereKey($user->id)->where('clan_attack_games', '>', 0)->decrement('clan_attack_games') > 0
            || User::query()->whereKey($user->id)->where('clan_games', '>', 0)->decrement('clan_games') > 0;
    }

    public function bindRun(Run $run, ?ClanAction $action = null): ?ClanAction
    {
        if ($run->daily_game_id) {
            return null;
        }

        $action ??= $this->pendingAction($run->user_id, $run->game_id);
        $action?->update(['run_id' => $run->id]);

        return $action;
    }

    /**
     * @return array{type: string, result: string, message: string}|null
     */
    public function handleRunCompleted(Run $run): ?array
    {
        $action = ClanAction::query()->where('run_id', $run->id)->whereNull('completed_at')->first();
        if (!$action) {
            return null;
        }

        $result = $run->is_cheat ? 'cheat' : match ($action->type) {
            ClanActionType::ATTACK => $this->warService->completeAttack($action, $run),
            ClanActionType::DEFENSE => $this->warService->completeDefense($action, $run),
            ClanActionType::MISSION => $this->missionService->completeStep($action, $run),
        };
        $action->update(['result' => $result, 'completed_at' => now()]);

        return [
            'type' => $action->type->value,
            'result' => $result,
            'message' => $this->message($action->type, $result),
        ];
    }

    private function message(ClanActionType $type, string $result): string
    {
        return match ([$type, $result]) {
            [ClanActionType::ATTACK, 'launched'] => 'Votre attaque est lancée ! Le clan adverse a '.config('kado.clans.attack_hours').' heures pour la repousser.',
            [ClanActionType::ATTACK, 'improved'] => 'Votre attaque est améliorée : le clan adverse devra battre ce nouveau score.',
            [ClanActionType::ATTACK, 'not_improved'] => 'Ce score n\'est pas meilleur que celui de votre attaque : elle garde son score.',
            [ClanActionType::DEFENSE, 'repelled'] => 'Bravo, vous avez repoussé l\'attaque !',
            [ClanActionType::DEFENSE, 'failed'] => 'Votre score n\'est pas suffisant pour repousser l\'attaque.',
            [ClanActionType::MISSION, 'completed'] => 'Étape de mission réussie !',
            [ClanActionType::MISSION, 'failed'] => 'Le score à atteindre pour cette étape n\'est pas atteint.',
            default => $result === 'cheat' ? 'Cette partie ne compte pas pour votre clan.' : 'Trop tard : cette action de clan est terminée.',
        };
    }
}
