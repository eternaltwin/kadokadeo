<?php

namespace App\Push;

use App\Models\PushSubscription;
use GuzzleHttp\Psr7\HttpFactory;
use Minishlink\WebPush\MessageSentReport;
use Minishlink\WebPush\Subscription;
use Minishlink\WebPush\WebPush;
use Psr\Http\Client\ClientInterface;
use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\Response;

// the only place that knows the library
class WebPushSender implements PushSender
{
    public const KEPT_WHILE_THE_DEVICE_SLEEPS_IN_SECONDS = 86400;

    private readonly WebPush $webPush;

    // (its warnings in the log: without it they are PHP notices, turned into exceptions by Laravel, e.g. a server without
    // the GMP or BCMath extension could send no push)
    /** @param array{subject: string, publicKey: string, privateKey: string} $vapid */
    public function __construct(array $vapid, ClientInterface $http, LoggerInterface $log)
    {
        $factory = new HttpFactory();
        $this->webPush = new WebPush(['VAPID' => $vapid], ['TTL' => self::KEPT_WHILE_THE_DEVICE_SLEEPS_IN_SECONDS], $http, $factory, $factory, logger: $log);
    }

    public function send(PushSubscription $subscription, PushMessage $message): PushOutcome
    {
        $device = Subscription::create([
            'endpoint' => $subscription->endpoint,
            'publicKey' => $subscription->public_key,
            'authToken' => $subscription->auth_token,
            'contentEncoding' => 'aes128gcm',
        ]);

        return $this->outcomeOf($this->webPush->sendOneNotification($device, json_encode($message->payload(), JSON_THROW_ON_ERROR)));
    }

    private function outcomeOf(MessageSentReport $report): PushOutcome
    {
        $status = $report->getResponse()?->getStatusCode();

        return match (true) {
            $report->isSuccess() => PushOutcome::DELIVERED,
            $report->isSubscriptionExpired() => PushOutcome::GONE,
            $status === null, $status === Response::HTTP_TOO_MANY_REQUESTS, $status >= Response::HTTP_INTERNAL_SERVER_ERROR => PushOutcome::RETRY,
            default => PushOutcome::REJECTED,
        };
    }
}
