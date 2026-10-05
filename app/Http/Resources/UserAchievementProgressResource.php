<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserAchievementProgressResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'achievement_id' => $this->achievement_id,
            'period_id' => $this->period_id,
            'current_value' => $this->current_value,
            'completed_level' => $this->completed_level,
            'completed_at' => $this->completed_at,
        ];
    }
}
