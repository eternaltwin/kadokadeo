<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RunEndRequest;
use App\Http\Requests\RunStartRequest;
use App\Http\Resources\RunBeginResource;
use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Services\GameService;
use App\Services\RunService;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
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
        [$score, $points] = $gameService->getContract($game);

        $run = $game->runs()->create([
            'user_id' => Auth::id(),
            'period_id' => Period::current()->first(),
            'seed' => $gameService->generateSeed(),
            'contract_score' => $score,
            'contract_points' => $points,
        ]);

        return new RunBeginResource($run);
    }

    public function end(RunEndRequest $request, Run $run, RunService $runService)
    {
        $payload = $request->validated('payload');
        $key = $request->validated('key');
        $sign = $request->validated('sign');

        try {
            $decoded = $runService->decodeRun($payload, $key, $sign);
            $run = $runService->confirmRun($run, $decoded);
        } catch (\Throwable $e) {
            info(sprintf('RunController@end: user %d run end failed: %s', Auth::id(), $e->getMessage()));
            throw new BadRequestException($e->getMessage());
        }

        return new JsonResource($run);
    }
}
