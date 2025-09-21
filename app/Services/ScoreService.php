<?php

namespace App\Services;

use App\Models\Game;
use App\Models\Run;
use Illuminate\Support\Facades\DB;

class ScoreService
{
    public function __construct()
    {
    }

    /**
     * @return \Illuminate\Support\Collection<\App\Models\Run>
     */
    public function getLeaderBoard(Game $game, $count = 10): \Illuminate\Support\Collection
    {
        $sub = $game->runs()
            ->select('user_id', DB::raw('MAX(score) as max_score'))
            ->groupBy('user_id');

        $scores = $game->runs()
            ->joinSub($sub, 'best', function ($join) {
                $join->on('runs.user_id', '=', 'best.user_id')
                     ->on('runs.score', '=', 'best.max_score');
            })
            ->with('user')
            ->select(
                'runs.user_id',
                'runs.score',
                'runs.id',
                DB::raw('CASE WHEN runs.replay IS NULL THEN 0 ELSE 1 END as replay')
            )
            ->orderByDesc('runs.score')
            ->take($count)
            ->get();

        return $scores;
    }

    public function getUserBestScore(Game $game, int $userId, ?int $periodId = null): ?Run
    {
        return $game->runs()
            ->whereNotNull('score')
            ->when($periodId, fn ($q) => $q->where('period_id', $periodId))
            ->where('user_id', $userId)
            ->orderBy('score', 'desc')
            ->first();
    }
}
