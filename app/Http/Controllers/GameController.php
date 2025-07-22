<?php

namespace App\Http\Controllers;

use App\Models\Game;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

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

        $gamesQ = \App\Models\Game::query();
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
        return view('pages.games.show', ['game' => $game]);
    }
}
