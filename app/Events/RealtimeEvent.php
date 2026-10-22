<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;

// an event of the realtime of the site, sent by App\Support\Realtime::send. Not queued: the only worker also verifies the
// replays (minutes in a browser), the events would wait behind them. Listened by the front as ".<broadcastAs()>"
abstract class RealtimeEvent implements ShouldBroadcastNow
{
    /** @return Channel|Channel[] */
    abstract public function broadcastOn(): Channel|array;

    abstract public function broadcastAs(): string;

    /** @return array<string, mixed> */
    public function broadcastWith(): array
    {
        return [];
    }
}
