<?php

namespace App\Http\Resources;

use App\Support\GameBuilds\GameBuildArchive;
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
        $isAdmin = $request->user()?->is_admin ?? false;

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
            'league_id' => $this->league_id,
            'rank_position' => $this->whenHas('rank_position', $this->rank_position),
            'league_rank' => $this->whenHas('league_rank', $this->league_rank),
            'replay' => $this->replay,
            'has_replay' => $this->has_replay,
            // the bundle the replay has to be played with (the version of the game it was recorded with)
            'gamedata' => $this->when(
                $this->has_replay && $this->relationLoaded('game'),
                fn () => app(GameBuildArchive::class)->gamedataFor($this->game, $this->gameBuild),
            ),
            'completed_at' => $this->completed_at,
            'is_cheat' => $this->when($isAdmin, $this->is_cheat),
        ];
    }
}
