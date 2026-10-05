<?php

namespace App\Http\Controllers;

use App\Models\Run;
use App\Support\GameBuilds\GameBuildArchive;

/**
 * The replay of a run in the admin panel (in a modal: App\Filament\Resources\Runs\RunVerificationTable::replayAction),
 * outside of the site: the admin is logged in the panel, not always in the site. Played like on the replay page of
 * the site (resources/js/pages/runs/show.vue), with the version of the game it was recorded with.
 */
class RunReplayController extends Controller
{
    public function __invoke(string $run, GameBuildArchive $archive)
    {
        $run = Run::withTrashed()->with('game', 'gameBuild')->findOrFail($run);
        $gamedata = $run->game ? $archive->gamedataFor($run->game, $run->gameBuild) : null;

        // the fonts of the site (some games measure their texts), without its styles
        preg_match_all('/@font-face\s*{[^}]*}/', (string) @file_get_contents(resource_path('css/app.css')), $fontFaces);

        return view('admin.run-replay', [
            'fontFaces' => implode("\n", $fontFaces[0]),
            'player' => $gamedata === null || !$run->replay ? null : [
                'game' => [
                    'id' => $run->game->id,
                    'name' => $run->game->name,
                    'pascal_name' => $run->game->pascal_name,
                    'gamedata' => $gamedata,
                ],
                'args' => [
                    'replayData' => $run->replay,
                    'seed' => $run->seed,
                    'contractScore' => $run->contract_score,
                    'contractPoints' => $run->contract_points,
                    'assetBase' => $gamedata['asset_base'] ?? null,
                ],
            ],
        ]);
    }
}
