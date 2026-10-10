<?php

namespace App\Services;

use App\Enums\ClanActionType;
use App\Models\ClanAction;
use App\Models\Run;

// a clan run is a normal run (contract, rankings): the player asks for it on the clan pages (ClanAction), then the next
// run he begins on the game is bound to it, and its score is used when it ends. An attack or a defense costs a game
// like any run, a mission step is free (RunController::begin).
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

    // the runs of the missions don't cost a game
    public function isFree(?ClanAction $action): bool
    {
        return $action?->type === ClanActionType::MISSION;
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
