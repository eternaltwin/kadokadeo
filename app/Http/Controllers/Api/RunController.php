<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RunEndRequest;
use App\Http\Requests\RunStartRequest;
use App\Http\Resources\RunBeginResource;
use App\Http\Resources\RunResource;
use App\Models\Game;
use App\Models\GameBuild;
use App\Models\Period;
use App\Models\Run;
use App\Services\GameService;
use App\Services\LeagueService;
use App\Services\RunService;
use App\Services\ScoreService;
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
            new Middleware('auth:sanctum', except: ['publicKey']),
            new Middleware('throttle:10,1', only: ['begin']), // 10 requests per minute
        ];
    }

    public function begin(RunStartRequest $request, GameService $gameService, LeagueService $leagueService, Game $game)
    {
        Gate::authorize('create', Run::class);

        $isDaily = $request->validated('daily', false);
        $realContract = false;
        $dailyGame = null;

        if ($isDaily) {
            // If it's a daily run, check if the game is a daily game and if the user already played it today
            $dailyGate = Gate::inspect('playDaily', $game);
            $realContract = $dailyGate->allowed() || !app()->environment('production');
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
        $period = Period::current()->first();
        $membership = $period ? $leagueService->resolveMembership($user, $game, $period) : null;
        $run = $game->runs()->create([
            'user_id' => $user->id,
            'period_id' => $period?->id,
            'league_id' => $membership?->league_id,
            'seed' => $seed,
            'contract_score' => $score,
            'contract_points' => $points,
            'game_build_id' => GameBuild::resolve($game, $request->validated('build'))?->id,
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
        // a run sent again (offline retry, lost response) must not be rewarded twice
        if ($run->completed_at !== null) {
            abort(409, 'Partie déjà terminée.');
        }

        $user = $request->user();
        $periodId = $run->period_id ?? Period::current()->first()?->id;
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

        $leaderBoardQuery = $scoreService->getLeaderBoard($run->game, $periodId, $run->league_id);
        $toBeatCount = $leaderBoardQuery->where('runs.score', '>', $run->score)->count();
        $previousStar = $run->game->getStarFromScore($previousBestScore);

        return [
            'data' => [
                'is_best' => !$run->is_cheat && $run->score > $previousBestScore,
                'previous_star' => $previousStar,
                'current_star' => $run->is_cheat ? $previousStar : $run->game->getStarFromScore($run->score),
                'people_to_beat' => $toBeatCount,
            ],
        ];
    }

    /**
     * The key changes with each deployment: a page opened before it asks for it again when a run cannot be sent.
     */
    public function publicKey(RunService $runService)
    {
        return response()
            ->json(['data' => ['public_key' => $runService->getPublicKey()]])
            ->header('Cache-Control', 'no-store');
    }

    public function show(Run $run)
    {
        Gate::authorize('view', $run);
        $run->load('game', 'user', 'gameBuild');
        Gate::authorize('view', $run->game);

        return RunResource::make($run);
    }
}
