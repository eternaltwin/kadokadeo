<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Challenge1500Service;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

class Challenge1500Controller extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum'),
        ];
    }

    public function ranking(Request $request, Challenge1500Service $service)
    {
        $data = $request->validate([
            'period' => 'nullable|integer|min:1|max_digits:6|exists:periods,id',
        ]);

        return response()->json($service->getChallengeRanking(data_get($data, 'period')));
    }

    public function calculate(Request $request, Challenge1500Service $service)
    {
        $data = $request->validate([
            'gameId' => 'required|integer|min:1|exists:games,id',
            'score' => 'required|numeric|min:0',
        ]);

        return response()->json([
            'points' => $service->calculatePoints((int) $data['gameId'], (float) $data['score']),
        ]);
    }
}
