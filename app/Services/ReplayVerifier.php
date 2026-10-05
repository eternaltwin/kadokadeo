<?php

namespace App\Services;

use App\Models\Run;
use App\Support\GameBuilds\GameBuildArchive;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Str;
use Symfony\Component\Process\Process;

/**
 * Plays the replay of a run again in a headless Chrome (resources/js/replay-verifier/verify.mjs), with the version of
 * the game it was recorded with, and gives the score it ends with.
 */
class ReplayVerifier
{
    public function __construct(private readonly GameBuildArchive $archive) {}

    public function enabled(): bool
    {
        return (bool) config('kado.replay_verifier.enabled');
    }

    // the runs that count: a personal best (the leaderboards), a contract (kadopoints) or the daily game
    public function shouldVerify(Run $run, int $previousBestScore): bool
    {
        if (!$this->enabled() || $run->is_cheat) {
            return false;
        }

        return $run->score > $previousBestScore
            || ($run->contract_score > 0 && $run->score >= $run->contract_score)
            || $run->daily_game_id !== null;
    }

    /**
     * @return array{ok: bool, score?: int, frames?: int, error?: string}
     */
    public function verify(Run $run): array
    {
        $game = $run->game;
        $gamedata = $this->archive->gamedataFor($game, $run->gameBuild);
        if ($gamedata === null) {
            return ['ok' => false, 'error' => 'no bundle for this game'];
        }
        $key = $game->game_key;
        $bundle = $gamedata['file'] === "/gamesdata/{$key}.js"
            ? @file_get_contents(public_path("gamesdata/{$key}.js"))
            : $this->archive->bundle($key, $gamedata['hash']);
        if (!$bundle) {
            return ['ok' => false, 'error' => "bundle {$gamedata['file']} not found"];
        }

        $dir = storage_path('app/replay-verifier/runs/'.Str::random(16));
        File::ensureDirectoryExists($dir);
        try {
            file_put_contents("{$dir}/bundle.js", $bundle);
            file_put_contents("{$dir}/input.json", json_encode([
                'bundle' => "{$dir}/bundle.js",
                'gameClass' => $game->pascal_name,
                'gameName' => $key,
                'seed' => $run->seed,
                'replay' => $run->replay,
                'assetBase' => $gamedata['asset_base'] ?? null,
            ]));

            $result = $this->node(['verify.mjs', "{$dir}/input.json"], config('kado.replay_verifier.timeout'));
            if (!isset($result['ok'])) {
                return ['ok' => false, 'error' => $result['error'] ?? 'no result'];
            }

            return $result;
        } catch (\Throwable $e) {
            return ['ok' => false, 'error' => Str::limit($e->getMessage(), 500)];
        } finally {
            File::deleteDirectory($dir);
        }
    }

    /**
     * What the verifier needs on this server (resources/js/replay-verifier/check.mjs): Node, the browser (downloaded
     * first when there is none and $install), its missing system libraries, WebGL and fonts.
     *
     * @return array<string, mixed>
     */
    public function diagnose(bool $install = false): array
    {
        try {
            return $this->node(array_filter(['check.mjs', $install ? '--install' : null]), $install ? 600 : 120);
        } catch (\Throwable $e) {
            return ['error' => Str::limit($e->getMessage(), 500)];
        }
    }

    /**
     * Runs a script of resources/js/replay-verifier: its result is the last line of its output (JSON).
     *
     * @return array<string, mixed>
     */
    private function node(array $args, int $timeout): array
    {
        $args[0] = base_path('resources/js/replay-verifier/'.$args[0]);
        $process = new Process(
            [config('kado.replay_verifier.node'), ...$args],
            base_path(),
            array_filter(['BROWSER' => config('kado.replay_verifier.browser')]),
        );
        $process->setTimeout($timeout);
        $process->run();

        $lines = array_filter(explode("\n", trim($process->getOutput())));
        $result = json_decode((string) end($lines), true);
        if (!is_array($result)) {
            return ['error' => 'no result: '.Str::limit($process->getErrorOutput() ?: $process->getOutput(), 500)];
        }

        return $result;
    }
}
