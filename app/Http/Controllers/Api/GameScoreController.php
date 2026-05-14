<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\RunResource;
use App\Models\Game;
use App\Models\Period;
use App\Services\GameService;
use App\Services\LeagueService;
use App\Services\ScoreService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

class GameScoreController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum', only: ['index', 'show', 'daily', 'dailyScores']),
        ];
    }

    public function index(Game $game, ScoreService $scoreService, LeagueService $leagueService)
    {
        $currentPeriod = Period::current()->first();
        $league = $currentPeriod ? $leagueService->getCurrentLeagueFor(Auth::user(), $game, $currentPeriod) : null;
        $scores = $scoreService->getLeaderBoard($game, $currentPeriod?->id, $league?->id)->take(10)->get();
        $personalBest = $scoreService->getUserBestScore($game, Auth::id());
        $personalBestForPeriod = $scoreService->getUserBestScore($game, Auth::id(), $currentPeriod?->id);
        $worldsBest = $scoreService->getUserBestScore($game, null);

        return response()->json([
            'scores' => RunResource::collection($scores),
            'worldsBest' => $worldsBest ? RunResource::make($worldsBest) : null,
            'personalBest' => $personalBest ? RunResource::make($personalBest) : null,
            'personalBestForPeriod' => $personalBestForPeriod ? RunResource::make($personalBestForPeriod) : null,
            'league' => $league,
        ]);
    }

    public function search(Request $request, Game $game, ScoreService $scoreService)
    {
        $data = $request->validate([
            'period' => 'sometimes|required|integer|min:1|max_digits:6|exists:periods,id',
            'league' => 'sometimes|required|integer|min:1|exists:leagues,id',
        ]);
        $scores = $scoreService->getLeaderBoard($game, data_get($data, 'period'), data_get($data, 'league'))->paginate(50);

        return RunResource::collection($scores);
    }

    public function dailyScores(Request $request, GameService $gameService, ScoreService $scoreService)
    {
        $dailyGame = $gameService->getDailyGame();
        Gate::authorize('view', $dailyGame?->game);

        $dailyGameRuns = $dailyGame?->runs()->whereNotNull('score')->orderByDesc('score')->with('user')->limit(10)->get() ?? collect();
        // hack to disable replay for this specific endpoint
        $dailyGameRuns->each(function ($run) {
            $run->replay = null;
        });

        $myPosition = $scoreService->getUserPositionOnDailyGame($dailyGame, Auth::id());

        return RunResource::collection($dailyGameRuns)
            ->additional([
                'position' => $myPosition,
            ]);
    }
}
