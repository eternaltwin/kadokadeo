<?php

namespace App\Achievements\Events;

use App\Achievements\AchievementEventPayload;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;

class GameRunCompleted implements AchievementEventPayload
{
    public function __construct(
        public readonly User $user,
        public readonly Game $game,
        public readonly Run $run,
        public readonly array $stats,
    ) {}

    public function gameKey(): string
    {
        return $this->game->game_key;
    }

    public function user(): User
    {
        return $this->user;
    }

    public function game(): Game
    {
        return $this->game;
    }

    public function periodId(): ?int
    {
        return $this->run->period_id;
    }

    public function sourceType(): string
    {
        return Run::class;
    }

    public function sourceId(): string
    {
        return (string) $this->run->id;
    }
}
