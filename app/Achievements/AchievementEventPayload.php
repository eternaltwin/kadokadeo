<?php

namespace App\Achievements;

use App\Models\Game;
use App\Models\User;

interface AchievementEventPayload
{
    public function user(): User;

    public function game(): Game;

    public function periodId(): ?int;

    public function sourceType(): string;

    public function sourceId(): string;
}
