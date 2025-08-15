<?php

namespace App\Http\Controllers;

use App\Models\Game;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class GameController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth', only: ['show']),
        ];
    }

    /**
     * Display a listing of the games.
     */
    public function index(Request $request)
    {
        $data = $request->validate([
            'category' => 'nullable|exists:categories,name',
        ]);
        $categoryName = data_get($data, 'category');

        $gamesQ = \App\Models\Game::where('is_active', true);
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
        $scores = $game->runs()
            ->with('user')
            ->groupBy('user_id')
            ->orderBy('score', 'desc')
            ->select(['user_id', DB::raw('MAX(score) as score')])
            ->take(10)
            ->get();
        $personalBest = $game->runs()->whereNotNull('score')->where('user_id', Auth::id())->orderBy('score', 'desc')->first();

        return view('pages.games.show', compact('game', 'scores', 'personalBest'));
    }
}
