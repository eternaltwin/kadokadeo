<?php

namespace App\Services;

use App\Enums\ClanActionType;
use App\Models\ClanAction;
use App\Models\Run;
use App\Models\User;

// a clan run is a normal run (contract, rankings): the player asks for it on the clan pages (ClanAction), then the next
// run he begins on the game is bound to it, and its score is used when it ends. A mission step is free, an attack or a
// defense costs a game of the day like any run, then a paid clan game (RunController::begin).
class ClanRunService
{
    public function __construct(
        private readonly ClanWarService $warService,
        private readonly ClanMissionService $missionService,
    ) {}

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

    public const COST_FREE = 'free';

    public const COST_GAME = 'game';

    public const COST_PAID = 'paid';

    // what the run costs: nothing for a mission step, a game of the day, or a paid clan game for an attack or a defense
    // once the games of the day are used
    public function runCost(User $user, ?ClanAction $action): string
    {
        if ($action?->type === ClanActionType::MISSION) {
            return self::COST_FREE;
        }
        if ($action && config('kado.games_per_day') > 0 && $user->kado_games <= 0 && $user->clan_games > 0) {
            return self::COST_PAID;
        }

        return self::COST_GAME;
    }

    // a paid clan game used, false when there was none left (another run in the meantime)
    public function usePaidGame(User $user): bool
    {
        return User::query()->whereKey($user->id)->where('clan_games', '>', 0)->decrement('clan_games') > 0;
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
