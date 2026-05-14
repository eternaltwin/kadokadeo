<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\GameResource;
use App\Models\Game;
use App\Services\GameService;
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
        $periodId = \App\Models\Period::current()->first()?->id;

        $gamesQ = Game::where('is_active', true);
        if ($categoryName) {
            $gamesQ->whereHas('category', function ($query) use ($categoryName) {
                $query->where('name', $categoryName);
            });
        }
        $games = $gamesQ->with(['periodStars' => function ($query) use ($periodId) {
            $query->where('user_id', Auth::id());
            $query->when($periodId, function ($q) use ($periodId) {
                $q->where('period_id', $periodId);
            });
            $query->orderBy('star', 'desc');
        }])->get();

        $categories = \App\Models\Category::all();

        return GameResource::collection($games)->additional([
            'categories' => $categories,
        ]);
    }

    public function show(Game $game)
    {
        Gate::authorize('view', $game);

        $game->load('controls');

        return GameResource::make($game);
    }

    public function daily(GameService $gameService)
    {
        $dailyGame = $gameService->getDailyGame();
        Gate::authorize('view', $dailyGame?->game);

        return GameResource::make($dailyGame->game)->additional([
            'dailyGame' => $dailyGame,
        ]);
    }
}
