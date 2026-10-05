<?php

namespace App\Achievements\Events;

use App\Achievements\AchievementEventPayload;
use App\Models\Game;
use App\Models\League;
use App\Models\LeaguePromotion;
use App\Models\Period;
use App\Models\User;

class LeagueChanged implements AchievementEventPayload
{
    public function __construct(
        public readonly User $user,
        public readonly Game $game,
        public readonly Period $period,
        public readonly League $fromLeague,
        public readonly League $toLeague,
        public readonly LeaguePromotion $promotion,
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
        return $this->period->id;
    }

    public function sourceType(): string
    {
        return LeaguePromotion::class;
    }

    public function sourceId(): string
    {
        return (string) $this->promotion->id;
    }
}
