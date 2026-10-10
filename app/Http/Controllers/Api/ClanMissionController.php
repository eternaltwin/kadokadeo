<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserLightResource;
use App\Models\Clan;
use App\Models\ClanBonus;
use App\Models\ClanMission;
use App\Models\ClanMissionStep;
use App\Services\ClanMissionService;
use App\Services\ClanService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

// "Mission": the mission in progress of the clan, the previous ones of the period and the options of the clan
class ClanMissionController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum'),
            new Middleware('throttle:30,1', only: ['play']),
        ];
    }

    public function __construct(
        private readonly ClanService $clanService,
        private readonly ClanMissionService $missionService,
    ) {}

    public function index(Request $request, Clan $clan)
    {
        $this->clanService->assertMember($request->user(), $clan);
        $period = $this->clanService->currentPeriod();
        abort_unless($period, 404, 'Aucune période en cours.');

        $mission = $this->missionService->currentMission($clan, $period);
        $score = $this->clanService->periodScore($clan, $period)->load('bannedGame', 'forcedGame');

        return [
            'data' => [
                'mission' => $mission ? $this->missionData($mission->load('steps.game', 'steps.completedBy')) : null,
                'missions' => ClanMission::query()
                    ->where('clan_id', $clan->id)
                    ->where('period_id', $period->id)
                    ->where('status', '!=', ClanMission::ACTIVE)
                    ->orderByDesc('number')
                    ->get(['id', 'number', 'status', 'points', 'completed_at']),
                'mission_score' => $score->mission_score,
                'missions_completed' => $score->missions_completed,
                'banned_game' => $score->bannedGame?->only(['id', 'name']),
                'forced_game' => $score->forcedGame?->only(['id', 'name']),
                'bonuses' => ClanBonus::query()
                    ->available()
                    ->where('clan_id', $clan->id)
                    ->where('period_id', $period->id)
                    ->orderBy('id')
                    ->get()
                    ->map(fn (ClanBonus $bonus) => [
                        'id' => $bonus->id,
                        'type' => $bonus->type->value,
                        'label' => $bonus->type->getLabel(),
                        'description' => $bonus->type->description(),
                        'icon' => $bonus->type->icon(),
                    ]),
            ],
            'tournament' => $this->clanService->tournamentInfo(),
        ];
    }

    public function play(Request $request, ClanMissionStep $step)
    {
        $action = $this->missionService->startStep($request->user(), $step);

        return response()->json(['data' => ['id' => $action->id]], 201);
    }

    public function useBonus(Request $request, ClanBonus $bonus)
    {
        $validated = $request->validate([
            'game_id' => ['sometimes', 'integer'],
            'step_id' => ['sometimes', 'integer'],
        ]);
        $this->missionService->useBonus($request->user(), $bonus, $validated);

        return response()->noContent();
    }

    private function missionData(ClanMission $mission): array
    {
        return [
            'id' => $mission->id,
            'number' => $mission->number,
            'status' => $mission->status,
            'expires_at' => $mission->expires_at->toIso8601String(),
            // won if all the steps are done in time, otherwise 1 point lost by step not done, minus one
            'reward' => $this->missionService->missionPoints($mission->number),
            'steps' => $mission->steps->map(fn (ClanMissionStep $step) => [
                'id' => $step->id,
                'game' => ['id' => $step->game->id, 'name' => $step->game->name],
                'target_score' => $step->target_score,
                'skipped' => $step->skipped,
                'done' => $step->isDone(),
                'score' => $step->score,
                'completed_by' => $step->completedBy ? UserLightResource::make($step->completedBy) : null,
                'completed_at' => $step->completed_at?->toIso8601String(),
            ]),
        ];
    }
}
