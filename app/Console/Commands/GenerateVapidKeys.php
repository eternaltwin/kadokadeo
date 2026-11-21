<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Minishlink\WebPush\VAPID;

// once, before the pushes are turned on: new keys later make every device subscribe again
class GenerateVapidKeys extends Command
{
    protected $signature = 'kado:vapid-keys';

    protected $description = 'Shows a new pair of keys for the pushes (VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY), written nowhere';

    public function handle(): void
    {
        $keys = VAPID::createVapidKeys();
        $this->line("VAPID_PUBLIC_KEY={$keys['publicKey']}");
        $this->line("VAPID_PRIVATE_KEY={$keys['privateKey']}");
    }
}
