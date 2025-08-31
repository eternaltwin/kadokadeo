<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\HandlesAuthorization;

class RunPolicy
{
    use HandlesAuthorization;

    /**
     * Create a new policy instance.
     */
    public function create(User $user)
    {
        if ($user->kado_games <= 0) {
            return $this->deny('No games left');
        }

        return $this->allow();
    }

    public function view(User $user, $run)
    {
        if (!$run->replay) {
            return $this->deny('No replay for this run');
        }

        return $this->allow();
    }
}
