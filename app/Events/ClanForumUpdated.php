<?php

namespace App\Events;

use App\Support\Realtime;
use Illuminate\Broadcasting\Channel;

// a topic of the forum of the clan changed (new, answered, edited, moderated, deleted): the pages of the forum open on it
// reload it
class ClanForumUpdated extends RealtimeEvent
{
    public function __construct(private readonly int $clanId, private readonly int $topicId, private readonly bool $deleted = false) {}

    public function broadcastOn(): Channel
    {
        return Realtime::clan($this->clanId);
    }

    public function broadcastAs(): string
    {
        return 'clan.forum';
    }

    public function broadcastWith(): array
    {
        return ['topic_id' => $this->topicId, 'deleted' => $this->deleted];
    }
}
