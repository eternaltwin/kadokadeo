<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Clan;
use App\Models\ClanAction;
use App\Models\ClanAttack;
use App\Models\Game;
use App\Services\ClanWarService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;

// "Attaquer ce clan", "Améliorer", "Défendre", "Annuler": the run itself is played on the clan action page
// (ClanActionController)
class ClanWarController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum'),
            new Middleware('throttle:30,1', only: ['attack', 'improve', 'defend']),
        ];
    }

    public function __construct(private readonly ClanWarService $warService) {}

    public function attack(Request $request, Clan $clan)
    {
        $validated = $request->validate(['game_id' => ['required', 'integer', 'exists:games,id']]);
        $action = $this->warService->startAttack($request->user(), $clan, Game::query()->findOrFail($validated['game_id']));

        return $this->actionResponse($action);
    }

    public function improve(Request $request, ClanAttack $attack)
    {
        return $this->actionResponse($this->warService->startImprovement($request->user(), $attack));
    }

    public function defend(Request $request, ClanAttack $attack)
    {
        return $this->actionResponse($this->warService->startDefense($request->user(), $attack));
    }

    public function cancel(Request $request, ClanAttack $attack)
    {
        $this->warService->cancelAttack($request->user(), $attack);

        return response()->noContent();
    }

    private function actionResponse(ClanAction $action)
    {
        return response()->json(['data' => ['id' => $action->id]], 201);
    }
}
