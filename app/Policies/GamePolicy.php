<?php

namespace App\Policies;

use App\Models\DailyGame;
use App\Models\Game;
use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class GamePolicy
{
    use HandlesAuthorization;

    public function view(User $user, Game $game)
    {
        if (!$game->is_active) {
            return $this->deny('Game not active');
        }

        if (!$game->gamedata) {
            return $this->deny('Game data not available');
        }

        return $this->allow();
    }

    public function playDaily(User $user, Game $game)
    {
        $dailyGame = DailyGame::where('day', now()->today())
            ->where('game_id', $game->id)
            ->first();

        if (!$dailyGame) {
            return $this->deny('This game is not available as a daily game today');
        }

        $alreadyPlayed = $dailyGame->runs()
            ->where('user_id', $user->id)
            ->exists();

        if ($alreadyPlayed) {
            return $this->deny('You have already played the daily game today');
        }

        return $this->allow();
    }
}
