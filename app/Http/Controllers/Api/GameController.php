<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GameResource;
use App\Http\Resources\RunResource;
use App\Models\Game;
use App\Models\Period;
use App\Services\GameService;
use App\Services\ScoreService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;

class GameController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum', only: ['index', 'show', 'daily']),
        ];
    }

    /**
     * Display a listing of the games.
     */
    public function index(Request $request)
    {
        $data = $request->validate([
            'category' => 'sometimes|required|string|max:255|exists:categories,name',
        ]);
        $categoryName = data_get($data, 'category');

        $gamesQ = Game::where('is_active', true);
        if ($categoryName) {
            $gamesQ->whereHas('category', function ($query) use ($categoryName) {
                $query->where('name', $categoryName);
            });
        }
        $games = $gamesQ->get();

        $categories = \App\Models\Category::all();

        return GameResource::collection($games)->additional([
            'categories' => $categories,
        ]);
    }

    public function show(Game $game, ScoreService $scoreService)
    {
        Gate::authorize('view', $game);
        $currentPeriod = Period::current()->first();
        $scores = $scoreService->getLeaderBoard($game, 10);
        $personalBest = $scoreService->getUserBestScore($game, Auth::id());
        $personalBestForPeriod = $scoreService->getUserBestScore($game, Auth::id(), $currentPeriod?->id);

        return GameResource::make($game)->additional([
            'leaderboard' => RunResource::collection($scores),
            'personalBest' => RunResource::make($personalBest),
            'personalBestForPeriod' => RunResource::make($personalBestForPeriod),
            'currentPeriod' => $currentPeriod,
        ]);
    }

    public function daily(GameService $gameService)
    {
        $dailyGame = $gameService->getDailyGame();
        Gate::authorize('view', $dailyGame?->game);

        $dailyGameRuns = $dailyGame?->runs()->orderByDesc('score')->with('user')->limit(10)->get() ?? collect();

        return GameResource::make($dailyGame->game)->additional([
            'dailyGame' => $dailyGame,
            'leaderboard' => RunResource::collection($dailyGameRuns),
        ]);
    }
}
