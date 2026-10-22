<?php

namespace App\Events;

use App\Support\Realtime;
use Illuminate\Broadcasting\Channel;

// a new period (kado:prepare-new-period): the leagues, the scores, the tournament of the clans start again
class PeriodStarted extends RealtimeEvent
{
    public function broadcastOn(): Channel
    {
        return Realtime::site();
    }

    public function broadcastAs(): string
    {
        return 'period.started';
    }
}
