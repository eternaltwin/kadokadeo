<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RunResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user' => $this->whenLoaded('user', fn () => UserLightResource::make($this->user)),
            'game' => $this->whenLoaded('game', fn () => GameResource::make($this->game)),
            'score' => $this->score,
            'contract_score' => $this->contract_score,
            'contract_points' => $this->contract_points,
            'seed' => $this->seed,
            'play_time_seconds' => $this->play_time_seconds,
            'period_id' => $this->period_id,
            'replay' => $this->replay,
            'has_replay' => $this->replay !== null,
        ];
    }
}
