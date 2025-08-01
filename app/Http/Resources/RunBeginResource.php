<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RunBeginResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'run_id' => $this->id,
            'server_time' => $this->created_at->timestamp,
            'contract_score' => $this->contract_score,
            'contract_points' => $this->contract_points,
        ];
    }
}
