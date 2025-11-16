<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserStarResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'period_id' => $this->period_id,
            'green_stars' => $this->green_stars,
            'orange_stars' => $this->orange_stars,
            'red_stars' => $this->red_stars,
            'purple_stars' => $this->purple_stars,
        ];
    }
}
