<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'etwin_id' => $this->etwin_id,
            'display_name' => $this->display_name,
            'kado_points' => $this->kado_points,
            'kado_games' => $this->kado_games,
            // the paid clan games of the player (App\Services\ClanGameService)
            'clan_games' => $this->clan_games,
            'theme' => $this->theme ?? 'base',
            'stars' => $this->whenLoaded('stars', fn () => UserStarResource::make($this->stars->first())),
            'achievement_progress' => $this->whenLoaded('achievementProgress', fn () => UserAchievementProgressResource::collection($this->achievementProgress)),
        ];
    }
}
