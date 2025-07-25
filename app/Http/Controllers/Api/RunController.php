<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\RunEndRequest;
use App\Http\Requests\RunStartRequest;
use App\Models\Game;
use App\Models\Period;
use App\Services\RunService;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Exception\BadRequestException;

class RunController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth'),
            new Middleware('throttle:10,1', only: ['begin']), // 10 requests per minute
        ];
    }

    public function begin(RunStartRequest $request, Game $game)
    {
        $run = $game->runs()->create([
            'user_id' => Auth::id(),
            'period_id' => Period::current()->first(),
        ]);

        return $run->id;
    }

    public function end(RunEndRequest $request, RunService $runService)
    {
        $payload = $request->validated('payload');
        $key = $request->validated('key');
        $sign = $request->validated('sign');

        try {
            $decoded = $runService->decodeRun($payload, $key, $sign);
            dd($decoded);
            $run = $runService->confirmRun($decoded);
        } catch (\Exception $e) {
            throw new BadRequestException($e->getMessage());
        }


    }
}
