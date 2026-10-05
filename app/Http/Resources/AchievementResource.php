<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AchievementResource extends JsonResource
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
            'game' => $this->whenLoaded('game', fn () => GameResource::make($this->game)),
            'category' => $this->category,
            'progress_scope' => $this->progress_scope,
            'levels' => $this->whenLoaded('levels', fn () => AchievementLevelResource::collection($this->levels)),
            'level_user_counts' => $this->when(isset($this->level_user_counts), fn () => $this->level_user_counts),
        ];
    }
}
