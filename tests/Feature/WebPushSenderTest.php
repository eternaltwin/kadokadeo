<?php

namespace Tests\Feature;

use App\Models\PushSubscription;
use App\Push\PushMessage;
use App\Push\PushOutcome;
use App\Push\PushSender;
use App\Push\WebPushSender;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\ConnectException;
use GuzzleHttp\Handler\MockHandler;
use GuzzleHttp\HandlerStack;
use GuzzleHttp\Middleware;
use GuzzleHttp\Psr7\Request;
use GuzzleHttp\Psr7\Response;
use Minishlink\WebPush\VAPID;
use PHPUnit\Framework\Attributes\DataProvider;
use Psr\Http\Message\RequestInterface;
use Symfony\Component\HttpFoundation\Response as Status;
use Tests\TestCase;

class WebPushSenderTest extends TestCase
{
    private const ENDPOINT = 'https://fcm.googleapis.com/fcm/send/device-1';

    /** @var list<array{request: RequestInterface}> */
    private array $sent = [];

    public static function answers(): array
    {
        return [
            'created' => [new Response(Status::HTTP_CREATED), PushOutcome::DELIVERED],
            'gone' => [new Response(Status::HTTP_GONE), PushOutcome::GONE],
            'not found' => [new Response(Status::HTTP_NOT_FOUND), PushOutcome::GONE],
            'too many requests' => [new Response(Status::HTTP_TOO_MANY_REQUESTS), PushOutcome::RETRY],
            'unavailable' => [new Response(Status::HTTP_SERVICE_UNAVAILABLE), PushOutcome::RETRY],
            'bad request' => [new Response(Status::HTTP_BAD_REQUEST), PushOutcome::REJECTED],
            'forbidden (the keys of the server)' => [new Response(Status::HTTP_FORBIDDEN), PushOutcome::REJECTED],
            'payload too large' => [new Response(Status::HTTP_REQUEST_ENTITY_TOO_LARGE), PushOutcome::REJECTED],
        ];
    }

    #[DataProvider('answers')]
    public function test_the_answer_of_the_push_service_says_what_to_do(Response $answer, PushOutcome $outcome): void
    {
        $this->assertSame($outcome, $this->aSender($answer)->send($this->aDevice(), $this->aMessage()));
    }

    public function test_the_sender_of_the_site_is_made_from_its_keys_alone(): void
    {
        $keys = VAPID::createVapidKeys();
        config(['services.webpush' => ['public_key' => $keys['publicKey'], 'private_key' => $keys['privateKey'], 'subject' => null]]);

        $this->assertInstanceOf(WebPushSender::class, app(PushSender::class));
    }

    public function test_a_push_service_out_of_reach_is_tried_again(): void
    {
        $sender = $this->aSender(new ConnectException('timeout', new Request('POST', self::ENDPOINT)));

        $this->assertSame(PushOutcome::RETRY, $sender->send($this->aDevice(), $this->aMessage()));
    }

    public function test_the_push_goes_encrypted_to_the_device_and_is_kept_a_day_while_it_sleeps(): void
    {
        $this->aSender(new Response(Status::HTTP_CREATED))->send($this->aDevice(), $this->aMessage());

        $request = $this->sent[0]['request'];
        $this->assertSame(self::ENDPOINT, (string) $request->getUri());
        $this->assertSame('aes128gcm', $request->getHeaderLine('Content-Encoding'));
        $this->assertSame((string) WebPushSender::KEPT_WHILE_THE_DEVICE_SLEEPS_IN_SECONDS, $request->getHeaderLine('TTL'));
        $this->assertStringStartsWith('vapid ', $request->getHeaderLine('Authorization'));
        $this->assertStringNotContainsString('A comment', (string) $request->getBody());
    }

    private function aSender(Response|ConnectException $answer): WebPushSender
    {
        $handler = HandlerStack::create(new MockHandler([$answer]));
        $handler->push(Middleware::history($this->sent));

        return new WebPushSender(['subject' => 'https://kadokadeo.example', ...VAPID::createVapidKeys()], new Client(['handler' => $handler]), app('log'));
    }

    private function aDevice(): PushSubscription
    {
        $device = openssl_pkey_get_details(openssl_pkey_new(['private_key_type' => OPENSSL_KEYTYPE_EC, 'curve_name' => 'prime256v1']))['ec'];
        $base64url = fn (string $bytes) => rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');

        return new PushSubscription([
            'endpoint' => self::ENDPOINT,
            'public_key' => $base64url("\x04".$device['x'].$device['y']),
            'auth_token' => $base64url(random_bytes(16)),
        ]);
    }

    private function aMessage(): PushMessage
    {
        return PushMessage::ofNotification(1, title: 'A comment', body: 'on your replay', url: '/runs/1');
    }
}
