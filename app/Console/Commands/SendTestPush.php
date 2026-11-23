<?php

namespace App\Console\Commands;

use App\Models\PushSubscription;
use App\Push\PushMessages;
use App\Push\PushSender;
use Illuminate\Console\Command;

class SendTestPush extends Command
{
    protected $signature = 'kado:push-test {user : the id of the player}';

    protected $description = 'Sends a test push to each device of a player and shows what its push service answered';

    public function handle(): int
    {
        $devices = PushSubscription::query()->where('user_id', $this->argument('user'))->get();
        if ($devices->isEmpty()) {
            $this->error('This player has no device subscribed to the pushes.');

            return self::FAILURE;
        }

        // (after: the keys are read when the sender is made)
        $pushServices = app(PushSender::class);
        $message = PushMessages::test(app()->getLocale());
        foreach ($devices as $device) {
            $this->line("{$device->endpoint}: {$pushServices->send($device, $message)->name}");
        }

        return self::SUCCESS;
    }
}
