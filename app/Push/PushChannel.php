<?php

namespace App\Push;

use App\Jobs\SendPush;
use App\Models\PushSubscription;
use App\Models\UserNotification;
use App\Settings\SiteSettings;

// One job by device: a push service down does not hold back the others. Called in the transaction of the notification:
// the jobs are rows of the same database (queue "database"), written with it or not at all.
class PushChannel
{
    public function __construct(private readonly SiteSettings $settings) {}

    public function notify(UserNotification $notification): void
    {
        if (!$this->settings->push_enabled || !$notification->type->interruptsPlayer()) {
            return;
        }

        PushSubscription::query()->where('user_id', $notification->user_id)->pluck('id')
            ->each(fn (int $subscriptionId) => SendPush::dispatch($subscriptionId, $notification->id));
    }
}
