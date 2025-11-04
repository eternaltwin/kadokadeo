<?php

namespace App\Http\Controllers;

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
            new Middleware('auth', only: ['show', 'daily']),
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

        return view('pages.games.index', compact('games', 'categories'));
    }

    public function show(Game $game, ScoreService $scoreService)
    {
        Gate::authorize('view', $game);
        $currentPeriod = Period::current()->first();
        $scores = $scoreService->getLeaderBoard($game, 10);
        $personalBest = $scoreService->getUserBestScore($game, Auth::id());
        $personalBestForPeriod = $scoreService->getUserBestScore($game, Auth::id(), $currentPeriod?->id);

        return view('pages.games.show', compact('game', 'scores', 'personalBest', 'personalBestForPeriod'));
    }

    public function daily(GameService $gameService)
    {
        $dailyGame = $gameService->getDailyGame();
        Gate::authorize('view', $dailyGame?->game);

        $dailyGameRuns = $dailyGame?->runs()->orderByDesc('score')->with('user')->limit(10)->get() ?? collect();

        return view('pages.games.daily', compact('dailyGame', 'dailyGameRuns'));
    }
}
