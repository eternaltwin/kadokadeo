<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\RunResource;
use App\Models\Game;
use App\Models\Period;
use App\Services\ScoreService;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;

class GameScoreController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum', only: ['index', 'show', 'daily']),
        ];
    }

    public function index(Game $game, ScoreService $scoreService)
    {
        $currentPeriod = Period::current()->first();
        $scores = $scoreService->getLeaderBoard($game, 10);
        $personalBest = $scoreService->getUserBestScore($game, Auth::id());
        $personalBestForPeriod = $scoreService->getUserBestScore($game, Auth::id(), $currentPeriod?->id);

        return response()->json([
            'scores' => RunResource::collection($scores),
            'personalBest' => RunResource::make($personalBest),
            'personalBestForPeriod' => RunResource::make($personalBestForPeriod),
        ]);
    }
}
