<?php

namespace App\Services;

use App\Enums\AntiCheatBit;
use App\Enums\RunFlagRule;
use App\Models\Run;
use App\Models\RunFlag;
use Illuminate\Support\Facades\Cache;

/**
 * ANTI CHEAT: a run whose inputs come from the player (its replay gives its score) can still be played with help (a
 * script showing the best move...). The runs that look like it go in the queue of the suspicious runs of the admin
 * (Runs suspectes): nothing is sanctioned here, an admin decides.
 */
class SuspicionService
{
    // frames of the game by second (kado.FixedFramerate)
    private const FRAMES_PER_SECOND = 32;

    // a run just finished (App\Jobs\EvaluateRunSuspicion)
    public function evaluateFinishedRun(Run $run): void
    {
        if (!config('kado.suspicion.enabled') || $run->is_cheat || $run->completed_at === null) {
            return;
        }

        $this->checkClientDetections($run);
        $this->checkRealTime($run);
        $this->checkScore($run);
    }

    // the result of the analyzer of the game (App\Jobs\VerifyRunReplay)
    public function recordAnalysis(Run $run, ?array $analysis): void
    {
        if (!$analysis || !($analysis['suspicious'] ?? false) || !config('kado.replay_analysis.flag')) {
            return;
        }
        $this->flag($run, RunFlagRule::GAME_ANALYSIS, 2, [
            'analyzer' => $analysis['analyzer'] ?? null,
            'metrics' => $analysis['metrics'] ?? [],
            'reasons' => $analysis['reasons'] ?? [],
        ]);
    }

    private function checkClientDetections(Run $run): void
    {
        $bits = AntiCheatBit::softBits((int) $run->anticheat_flags);
        if ($bits !== 0) {
            $this->flag($run, RunFlagRule::CLIENT_DETECTION, 2, ['bits' => $bits]);
        }
    }

    // the time of the game (frames of its replay) against the time between its beginning and its end on the server: a
    // game can only be late (lag, tab hidden then caught up), not ahead
    private function checkRealTime(Run $run): void
    {
        if ($run->replay_frames === null || $run->play_time_seconds === null) {
            return;
        }
        $gameSeconds = $run->replay_frames / self::FRAMES_PER_SECOND;
        $realSeconds = (int) $run->play_time_seconds;
        $details = ['game_seconds' => round($gameSeconds, 1), 'real_seconds' => $realSeconds, 'frames' => $run->replay_frames];

        $allowed = $realSeconds * (1 + config('kado.suspicion.wall_clock_tolerance')) + config('kado.suspicion.wall_clock_margin_seconds');
        if ($gameSeconds > $allowed) {
            $this->flag($run, RunFlagRule::FASTER_THAN_REAL_TIME, 3, $details);

            return;
        }

        if (config('kado.suspicion.slow_motion')
            && $gameSeconds < $realSeconds * config('kado.suspicion.slow_ratio')
            && $realSeconds - $gameSeconds > config('kado.suspicion.slow_min_seconds')) {
            $this->flag($run, RunFlagRule::SLOW_MOTION, 1, $details);
        }
    }

    private function checkScore(Run $run): void
    {
        $history = Run::query()
            ->where('user_id', $run->user_id)
            ->where('game_id', $run->game_id)
            ->whereKeyNot($run->getKey())
            ->whereNotNull('completed_at')
            ->where('is_cheat', false)
            ->latest('completed_at')
            ->limit((int) config('kado.suspicion.history_runs'))
            ->pluck('score')
            ->all();
        $gameThreshold = $this->gameScoreThreshold($run->game_id, 0.75);

        $aboveHistory = false;
        if (count($history) >= config('kado.suspicion.history_min_runs')) {
            $median = $this->median($history);
            $aboveHistory = $run->score > config('kado.suspicion.history_factor') * max($median, 1)
                && ($gameThreshold === null || $run->score >= $gameThreshold);
            if ($aboveHistory) {
                $this->flag($run, RunFlagRule::SCORE_ABOVE_HISTORY, 2, ['median' => $median, 'runs' => count($history), 'score' => $run->score]);
            }
        }

        // a new best score of the player among the very best of the game (not each run of the best players)
        $percentile = (float) config('kado.suspicion.game_percentile');
        $topThreshold = $this->gameScoreThreshold($run->game_id, $percentile);
        $previousBest = (int) Run::query()
            ->where('user_id', $run->user_id)
            ->where('game_id', $run->game_id)
            ->whereKeyNot($run->getKey())
            ->where('is_cheat', false)
            ->max('score');
        if ($topThreshold !== null && $run->score >= $topThreshold && $run->score > $previousBest) {
            $this->flag($run, RunFlagRule::SCORE_TOP_PERCENTILE, $aboveHistory ? 3 : 1, [
                'percentile' => $percentile,
                'threshold' => $topThreshold,
                'previous_best' => $previousBest,
                'score' => $run->score,
            ]);
        }
    }

    // the score at a percentile of the finished runs of a game (null: not enough runs), kept an hour
    private function gameScoreThreshold(int $gameId, float $percentile): ?int
    {
        return Cache::remember("suspicion:game-threshold:{$gameId}:{$percentile}", 3600, function () use ($gameId, $percentile) {
            $runs = Run::query()->where('game_id', $gameId)->whereNotNull('completed_at')->where('is_cheat', false);
            $count = (clone $runs)->count();
            if ($count < config('kado.suspicion.game_min_runs')) {
                return null;
            }

            return (int) $runs->orderByDesc('score')->skip((int) floor($count * (1 - $percentile)))->value('score');
        });
    }

    private function median(array $values): float
    {
        sort($values);
        $count = count($values);
        $middle = intdiv($count, 2);

        return $count % 2 ? (float) $values[$middle] : ($values[$middle - 1] + $values[$middle]) / 2;
    }

    // one flag by run and rule: evaluated again, it is updated (its review is kept)
    private function flag(Run $run, RunFlagRule $rule, int $severity, array $details): RunFlag
    {
        return RunFlag::updateOrCreate(
            ['run_id' => $run->id, 'rule' => $rule],
            ['user_id' => $run->user_id, 'game_id' => $run->game_id, 'severity' => $severity, 'details' => $details],
        );
    }
}
