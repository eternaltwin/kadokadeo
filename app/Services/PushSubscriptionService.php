<?php

namespace App\Services;

use App\Models\PushSubscription;
use App\Models\User;

// a device shared by two players belongs to the last one who subscribed it
class PushSubscriptionService
{
    // a player's old devices leave rather than piling up (a browser reinstalled gets a new address)
    public const MAX_DEVICES = 10;

    public function subscribe(User $player, string $endpoint, string $publicKey, string $authToken, ?string $acceptLanguage): void
    {
        PushSubscription::query()->updateOrCreate(['endpoint' => $endpoint], [
            'user_id' => $player->id,
            'public_key' => $publicKey,
            'auth_token' => $authToken,
            'accept_language' => $acceptLanguage,
        ]);

        $kept = PushSubscription::query()->where('user_id', $player->id)
            ->orderByDesc('updated_at')->orderByDesc('id')
            ->limit(self::MAX_DEVICES)->pluck('id');
        PushSubscription::query()->where('user_id', $player->id)->whereNotIn('id', $kept)->delete();
    }

    public function unsubscribe(User $player, string $endpoint): void
    {
        PushSubscription::query()->where('user_id', $player->id)->where('endpoint', $endpoint)->delete();
    }
}
