<?php

namespace App\Http\Resources;

use App\Enums\ClanAttackStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClanAttackResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $user = $request->user();
        $viewerClanId = $user?->clanMember?->clan_id;
        $isActive = $this->status === ClanAttackStatus::ACTIVE;

        return [
            'id' => $this->id,
            'status' => $this->status->value,
            'status_label' => $this->status->getLabel(),
            'game' => ['id' => $this->game->id, 'name' => $this->game->name],
            'score' => $this->score,
            'points' => $this->points,
            'expires_at' => $this->expires_at?->toIso8601String(),
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'attacker' => UserLightResource::make($this->attackerUser),
            'attacker_clan' => ['id' => $this->attackerClan->id, 'name' => $this->attackerClan->name],
            'defender_clan' => ['id' => $this->defenderClan->id, 'name' => $this->defenderClan->name],
            'defender' => $this->defenderUser ? UserLightResource::make($this->defenderUser) : null,
            'can_defend' => $isActive && $viewerClanId === $this->defender_clan_id,
            'can_improve' => $isActive && $user?->id === $this->attacker_user_id,
            'can_cancel' => $isActive && $user?->id === $this->attacker_user_id,
        ];
    }
}
