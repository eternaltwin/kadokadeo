<?php

namespace App\Http\Controllers;

use App\Models\DailyGame;
use App\Models\Game;
use App\Services\GameService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
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

    public function show(Game $game)
    {
        Gate::authorize('view', $game);
        $sub = $game->runs()
            ->select('user_id', DB::raw('MAX(score) as max_score'))
            ->groupBy('user_id');

        $scores = $game->runs()
            ->joinSub($sub, 'best', function ($join) {
                $join->on('runs.user_id', '=', 'best.user_id')
                     ->on('runs.score', '=', 'best.max_score');
            })
            ->with('user')
            ->select(
                'runs.user_id',
                'runs.score',
                'runs.id',
                DB::raw('CASE WHEN runs.replay IS NULL THEN 0 ELSE 1 END as has_replay')
            )
            ->orderByDesc('runs.score')
            ->take(10)
            ->get();
        $personalBest = $game->runs()->whereNotNull('score')->where('user_id', Auth::id())->orderBy('score', 'desc')->first();

        return view('pages.games.show', compact('game', 'scores', 'personalBest'));
    }

    public function daily(GameService $gameService)
    {
        $dailyGame = $gameService->getDailyGame();
        Gate::authorize('view', $dailyGame?->game);

        $dailyGameRuns = $dailyGame?->runs()->orderByDesc('score')->with('user')->limit(10)->get() ?? collect();

        return view('pages.games.daily', compact('dailyGame', 'dailyGameRuns'));
    }
}
