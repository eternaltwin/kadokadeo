<?php

namespace App\Console\Commands;

use App\Models\Game;
use App\Models\GameBuild;
use App\Support\GameBuilds\GameBuildArchive;
use Illuminate\Console\Command;

class KeepGameBuilds extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'kado:game-builds:keep';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'List the versions of the games still used by replays (the next build removes the others)';

    /**
     * Execute the console command.
     */
    public function handle(GameBuildArchive $archive)
    {
        $games = [];
        $builds = GameBuild::query()
            ->whereHas('runs', fn ($query) => $query->whereNotNull('replay'))
            ->with('game')
            ->get();
        foreach ($builds as $build) {
            $games[$build->game->game_key][] = $build->hash;
        }

        // runs recorded before the archive (no version): the bundle that was there when it was created
        $legacy = [];
        $legacyGames = Game::query()
            ->whereHas('runs', fn ($query) => $query->whereNotNull('replay')->whereNull('game_build_id'))
            ->get();
        foreach ($legacyGames as $game) {
            $legacy[$game->game_key] = true;
        }

        $archive->writeKeep($games, $legacy);
        $this->info(sprintf('%d versions used by replays, %d games with replays recorded before the archive', $builds->count(), count($legacy)));
    }
}
