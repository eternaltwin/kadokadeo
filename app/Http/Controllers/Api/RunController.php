<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RunEndRequest;
use App\Http\Requests\RunStartRequest;
use App\Http\Resources\RunBeginResource;
use App\Http\Resources\RunResource;
use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Services\GameService;
use App\Services\RunService;
use App\Services\ScoreService;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Gate;
use Symfony\Component\HttpFoundation\Exception\BadRequestException;

class RunController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum'),
            new Middleware('throttle:10,1', only: ['begin']), // 10 requests per minute
        ];
    }

    public function begin(RunStartRequest $request, GameService $gameService, Game $game)
    {
        Gate::authorize('create', Run::class);

        $isDaily = $request->validated('daily', false);
        $realContract = false;
        $dailyGame = null;

        if ($isDaily) {
            // If it's a daily run, check if the game is a daily game and if the user already played it today
            $dailyGate = Gate::inspect('playDaily', $game);
            $realContract = $dailyGate->allowed();
            $dailyGame = $gameService->getDailyGame();
        }

        if ($realContract && $dailyGame) {
            $score = $dailyGame->contract_score;
            $points = $dailyGame->contract_points;
            $seed = $dailyGame->seed;
        } else {
            $score = 0;
            $points = 0;
            $seed = $gameService->generateSeed();
        }

        $user = $request->user();
        $run = $game->runs()->create([
            'user_id' => $user->id,
            'period_id' => Period::current()->first()?->id,
            'seed' => $seed,
            'contract_score' => $score,
            'contract_points' => $points,
        ]);

        if ($dailyGame?->seed === $run->seed && $dailyGame?->game_id === $run->game_id) {
            $run->daily_game_id = $dailyGame->id;
            $run->save();
        }

        if ($user->kado_games > 0) {
            $user->kado_games -= 1;
            $user->save();
        }

        return new RunBeginResource($run);
    }

    public function end(RunEndRequest $request, Run $run, RunService $runService, ScoreService $scoreService)
    {
        $user = $request->user();
        $periodId = Period::current()->first()?->id;
        $payload = $request->validated('payload');
        $key = $request->validated('key');
        $sign = $request->validated('sign');

        $previousBest = $scoreService->getUserBestScore($run->game, $user->id, $periodId);
        $previousBestScore = ($previousBest?->score ?? 0);

        try {
            $decoded = $runService->decodeRun($payload, $key, $sign);
            $run = $runService->confirmRun($run, $decoded);
            $runService->rewardStars($run);
        } catch (\Throwable $e) {
            info(sprintf('RunController@end: user %d run end failed: %s', Auth::id(), $e->getMessage()));
            throw new BadRequestException($e->getMessage());
        }

        $leaderBoardQuery = $scoreService->getLeaderBoard($run->game, $periodId);
        $toBeatCount = $leaderBoardQuery->where('runs.score', '>', $run->score)->count();

        return [
            'is_best' => $run->score > $previousBestScore,
            'previous_star' => $run->game->getStarFromScore($previousBestScore),
            'current_star' => $run->game->getStarFromScore($run->score),
            'people_to_beat' => $toBeatCount,
        ];
    }

    public function show(Run $run)
    {
        Gate::authorize('view', $run);
        $run->load('game', 'user');
        Gate::authorize('view', $run->game);

        return RunResource::make($run);
    }
}
