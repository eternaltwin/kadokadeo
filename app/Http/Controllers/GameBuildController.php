<?php

namespace App\Http\Controllers;

use App\Support\GameBuilds\GameBuildArchive;
use RuntimeException;

/**
 * The bundle of an old version of a game (for a replay recorded with it): rebuilt from the current bundle and a delta
 * of the archive. Its content never changes (the URL holds its hash): cached for good by the browsers.
 */
class GameBuildController extends Controller
{
    public function bundle(string $game, string $file, GameBuildArchive $archive)
    {
        $hash = substr($file, 0, 12);
        try {
            $bytes = $archive->bundle($game, $hash);
        } catch (RuntimeException $e) {
            // a build is replacing the current bundle: back in a moment
            report($e);

            return response('', 503, ['Retry-After' => '30']);
        }
        abort_if($bytes === null, 404);

        return response($bytes, 200, [
            'Content-Type' => 'application/javascript; charset=utf-8',
            'Cache-Control' => 'public, max-age=31536000, immutable',
        ]);
    }
}
