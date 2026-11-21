<?php

namespace Tests\Fakes;

use App\Models\PushSubscription;
use App\Push\PushMessage;
use App\Push\PushOutcome;
use App\Push\PushSender;

class FakePushSender implements PushSender
{
    /** @var array<string, list<PushMessage>> the messages delivered, by endpoint */
    public array $delivered = [];

    /** @var array<string, list<PushOutcome>> the next answers, by endpoint */
    private array $answers = [];

    public function answers(string $endpoint, PushOutcome ...$outcomes): void
    {
        $this->answers[$endpoint] = $outcomes;
    }

    public function send(PushSubscription $subscription, PushMessage $message): PushOutcome
    {
        $this->answers[$subscription->endpoint] ??= [];
        $outcome = array_shift($this->answers[$subscription->endpoint]) ?? PushOutcome::DELIVERED;
        if ($outcome === PushOutcome::DELIVERED) {
            $this->delivered[$subscription->endpoint][] = $message;
        }

        return $outcome;
    }

    /** @return list<PushMessage> */
    public function deliveredTo(string $endpoint): array
    {
        return $this->delivered[$endpoint] ?? [];
    }
}
