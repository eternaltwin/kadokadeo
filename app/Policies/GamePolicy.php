<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class GamePolicy
{
    use HandlesAuthorization;

    public function view(User $user, $game)
    {
        if (!$game->is_active) {
            return $this->deny('Game not active');
        }

        if (!$game->gamedata) {
            return $this->deny('Game data not available');
        }

        return $this->allow();
    }
}
