<?php

namespace App\Push;

use App\Models\PushSubscription;

interface PushSender
{
    public function send(PushSubscription $subscription, PushMessage $message): PushOutcome;
}
