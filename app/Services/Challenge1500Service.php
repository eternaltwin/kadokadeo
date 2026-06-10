<?php

namespace App\Services;

use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Models\User;

class Challenge1500Service
{
    public function getChallengeRanking(?int $periodId = null): array
    {
        $periodId = $this->resolvePeriodId($periodId);

        return $this->buildRanking($periodId);
    }

    public function getAvailableGames(): array
    {
        $thresholds = $this->getThresholdsByGameId();
        $gameIds = array_keys($thresholds);

        return Game::query()
            ->whereIn('id', $gameIds)
            ->orderBy('name')
            ->get(['id', 'name'])
            ->map(fn (Game $game) => [
                'id' => $game->id,
                'name' => $game->name,
            ])
            ->values()
            ->all();
    }

    public function calculatePoints(int $gameId, float|int $score): int
    {
        $thresholds = $this->getThresholdsByGameId();
        $gameThresholds = $thresholds[$gameId] ?? null;

        if (!$gameThresholds) {
            return 0;
        }

        return $this->calculateGamePoints($score, $gameThresholds);
    }

    private function resolvePeriodId(?int $periodId): int
    {
        if ($periodId) {
            return $periodId;
        }

        return (int) Period::query()->current()->value('id');
    }

    private function buildRanking(int $periodId): array
    {
        $thresholds = $this->getThresholdsByGameId();
        if (empty($thresholds)) {
            return [];
        }

        $runs = Run::query()
            ->selectRaw('user_id, game_id, MAX(score) as best_score')
            ->where('period_id', $periodId)
            ->whereNotNull('score')
            ->whereIn('game_id', array_keys($thresholds))
            ->groupBy('user_id', 'game_id')
            ->get();

        $games = Game::query()->whereIn('id', array_keys($thresholds))->get(['id', 'name'])->keyBy('id');
        $users = User::query()->whereIn('id', $runs->pluck('user_id')->unique()->values())->get(['id', 'display_name', 'etwin_id'])->keyBy('id');

        $players = [];
        foreach ($runs as $run) {
            $gameThresholds = $thresholds[$run->game_id] ?? null;
            $game = $games[$run->game_id] ?? null;
            $user = $users[$run->user_id] ?? null;

            if (!$gameThresholds || !$game || !$user) {
                continue;
            }

            if (!isset($players[$run->user_id])) {
                $players[$run->user_id] = [
                    'name' => $user->display_name,
                    'userId' => $user->etwin_id,
                    'profileUrl' => '/profile/'.$user->etwin_id,
                    'gamePoints' => [],
                ];
            }

            $players[$run->user_id]['gamePoints'][] = [
                'game' => $game->name,
                'score' => (int) $run->best_score,
                'points' => $this->calculateGamePoints((int) $run->best_score, $gameThresholds),
            ];
        }

        $ranking = [];
        foreach ($players as $player) {
            usort($player['gamePoints'], fn (array $a, array $b) => $b['points'] <=> $a['points'] ?: $b['score'] <=> $a['score']);

            $bestGames = array_slice($player['gamePoints'], 0, 12);
            $totalPoints = array_sum(array_column($bestGames, 'points'));
            $rawScoreTotal = array_sum(array_column($bestGames, 'score'));

            $ranking[] = [
                'name' => $player['name'],
                'userId' => $player['userId'],
                'profileUrl' => $player['profileUrl'],
                'totalPoints' => $totalPoints,
                'bestGames' => $bestGames,
                'rawScoreTotal' => $rawScoreTotal,
            ];
        }

        usort($ranking, fn (array $a, array $b) => $b['totalPoints'] <=> $a['totalPoints'] ?: $b['rawScoreTotal'] <=> $a['rawScoreTotal']);

        foreach ($ranking as $index => &$player) {
            $player['rank'] = $index + 1;
            unset($player['rawScoreTotal']);
        }

        return $ranking;
    }

    private function getThresholdsByGameId(): array
    {
        $rows = $this->readThresholdRows(resource_path('data/challenge1500/paliers.json'));
        $games = Game::query()->get(['id', 'name'])->keyBy('id');

        $thresholdsByGameId = [];
        foreach ($rows as $row) {
            $gameId = isset($row['Game ID']) ? (int) $row['Game ID'] : null;

            if (!$gameId || !isset($games[$gameId])) {
                continue;
            }

            $thresholdsByGameId[$gameId] = [
                'green' => $this->toNumber($row['Etoile verte'] ?? null),
                'orange' => $this->toNumber($row['Etoile orange'] ?? null),
                'red' => $this->toNumber($row['Etoile rouge'] ?? null),
                'p1300' => $this->toNumber($row['Paliers des 1300'] ?? null),
                'p1400' => $this->toNumber($row['Paliers des 1400'] ?? null),
                'p1500' => $this->toNumber($row['Paliers des 1500'] ?? null),
            ];
        }

        return $thresholdsByGameId;
    }

    private function calculateGamePoints(float|int $score, array $thresholds): int
    {
        $steps = [[
            'score' => 0,
            'points' => 0,
        ]];

        if (!is_null($thresholds['green'])) {
            $steps[] = ['score' => $thresholds['green'], 'points' => 1000];
        }
        if (!is_null($thresholds['orange'])) {
            $steps[] = ['score' => $thresholds['orange'], 'points' => 1100];
        }
        if (!is_null($thresholds['red'])) {
            $steps[] = ['score' => $thresholds['red'], 'points' => 1150];
        }
        if (!is_null($thresholds['p1300'])) {
            $steps[] = ['score' => $thresholds['p1300'], 'points' => 1300];
        }
        if (!is_null($thresholds['p1400'])) {
            $steps[] = ['score' => $thresholds['p1400'], 'points' => 1400];
        }
        if (!is_null($thresholds['p1500'])) {
            $steps[] = ['score' => $thresholds['p1500'], 'points' => 1500];
        }

        usort($steps, fn (array $a, array $b) => $a['score'] <=> $b['score']);

        $maxStep = end($steps);
        if ($maxStep && $score >= $maxStep['score']) {
            return 1500;
        }

        for ($i = 0; $i < count($steps) - 1; $i++) {
            $current = $steps[$i];
            $next = $steps[$i + 1];

            if ($score >= $current['score'] && $score < $next['score']) {
                $deltaScore = $next['score'] - $current['score'];
                if ($deltaScore <= 0) {
                    return $current['points'];
                }
                $ratio = ($score - $current['score']) / $deltaScore;

                return (int) floor($current['points'] + $ratio * ($next['points'] - $current['points']));
            }
        }

        return 0;
    }

    private function toNumber(null|string|int|float $value): ?float
    {
        if (is_null($value) || $value === '') {
            return null;
        }

        $normalized = str_replace(',', '.', preg_replace('/\s+/', '', (string) $value));
        if (!is_numeric($normalized)) {
            return null;
        }

        return (float) $normalized;
    }

    private function readThresholdRows(string $filePath): array
    {
        if (!file_exists($filePath)) {
            return [];
        }

        $json = file_get_contents($filePath);
        if ($json === false) {
            return [];
        }

        $rows = json_decode($json, true);

        return is_array($rows) ? $rows : [];
    }
}
