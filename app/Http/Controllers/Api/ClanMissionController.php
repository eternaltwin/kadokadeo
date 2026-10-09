<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserLightResource;
use App\Models\Clan;
use App\Models\ClanBonus;
use App\Models\ClanMission;
use App\Models\ClanMissionStep;
use App\Models\User;
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
                    ->get(['id', 'number', 'status', 'points', 'double_points', 'completed_at']),
                'mission_score' => $score->mission_score,
                'missions_completed' => $score->missions_completed,
                'next_mission_double' => $score->next_mission_double,
                'banned_game' => $score->bannedGame?->only(['id', 'name']),
                'forced_game' => $score->forcedGame?->only(['id', 'name']),
                'bonuses' => ClanBonus::query()
                    ->available()
                    ->where('clan_id', $clan->id)
                    ->where('period_id', $period->id)
                    ->with('assignedUser')
                    ->orderBy('id')
                    ->get()
                    ->map(fn (ClanBonus $bonus) => [
                        'id' => $bonus->id,
                        'type' => $bonus->type->value,
                        'label' => $bonus->type->getLabel(),
                        'description' => $bonus->type->description(),
                        'icon' => $bonus->type->icon(),
                        'assignable' => $bonus->type->isAssignable(),
                        'assigned_user' => $bonus->assignedUser ? UserLightResource::make($bonus->assignedUser) : null,
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

    public function assignBonus(Request $request, ClanBonus $bonus)
    {
        $validated = $request->validate(['user' => ['required', 'uuid']]);
        $member = User::query()->where('etwin_id', $validated['user'])->firstOrFail();
        $this->missionService->assignBonus($request->user(), $bonus, $member);

        return response()->noContent();
    }

    private function missionData(ClanMission $mission): array
    {
        return [
            'id' => $mission->id,
            'number' => $mission->number,
            'status' => $mission->status,
            'double_points' => $mission->double_points,
            'expires_at' => $mission->expires_at->toIso8601String(),
            'points' => $mission->steps->where('skipped', false)->sum('points') * ($mission->double_points ? 2 : 1),
            'steps' => $mission->steps->map(fn (ClanMissionStep $step) => [
                'id' => $step->id,
                'game' => ['id' => $step->game->id, 'name' => $step->game->name],
                'target_score' => $step->target_score,
                'points' => $step->points,
                'skipped' => $step->skipped,
                'done' => $step->isDone(),
                'score' => $step->score,
                'completed_by' => $step->completedBy ? UserLightResource::make($step->completedBy) : null,
                'completed_at' => $step->completed_at?->toIso8601String(),
            ]),
        ];
    }
}
