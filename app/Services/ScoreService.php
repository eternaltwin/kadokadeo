<?php

namespace App\Services;

use App\Models\DailyGame;
use App\Models\Game;
use App\Models\Run;
use Illuminate\Support\Facades\DB;

class ScoreService
{
    public function __construct() {}

    public function getLeaderBoard(Game $game, $periodId = null): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        $sub = $game->runs()
            ->select('user_id', DB::raw('MAX(score) as max_score'))
            ->when($periodId, fn ($q) => $q->where('period_id', $periodId))
            ->groupBy('user_id');

        $scores = $game->runs()
            ->joinSub($sub, 'best', function ($join) {
                $join->on('runs.user_id', '=', 'best.user_id')
                    ->on('runs.score', '=', 'best.max_score');
            })
            ->with('user')
            ->select(
                'runs.period_id',
                'runs.user_id',
                'runs.score',
                'runs.play_time_seconds',
                'runs.id',
                DB::raw('CASE WHEN runs.replay IS NULL THEN NULL ELSE 1 END as replay')
            )
            ->orderByDesc('runs.score');

        return $scores;
    }

    public function getUserBestScore(Game $game, ?int $userId, ?int $periodId = null): ?Run
    {
        return $game->runs()
            ->whereNotNull('score')
            ->when($periodId, fn ($q) => $q->where('period_id', $periodId))
            ->when($userId, fn ($q) => $q->where('user_id', $userId))
            ->orderBy('score', 'desc')
            ->first();
    }

    public function getUserPositionOnDailyGame(DailyGame $game, int $userId): ?int
    {
        $rankedQuery = Run::query()
            ->select([
                'user_id',
                DB::raw('DENSE_RANK() OVER (ORDER BY score DESC NULLS LAST, play_time_seconds ASC) AS rank_position'),
            ])
            ->where('daily_game_id', $game->id);

        $result = DB::query()
            ->fromSub($rankedQuery, 'ranked')
            ->where('user_id', $userId)
            ->first();

        return $result?->rank_position;
    }
}
