<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GameResource extends JsonResource
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
            'category_id' => $this->category_id,
            'name' => $this->name,
            'description' => $this->description,
            'image_path' => $this->image_path,
            'stars' => $this->stars,
            'gamedata' => $this->gamedata,
            'controls' => GameControlResource::collection($this->whenLoaded('controls')),
        ];
    }
}
