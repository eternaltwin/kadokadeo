<?php

namespace Tests\Feature;

use App\Models\PushSubscription;
use App\Models\User;
use App\Push\PushOutcome;
use App\Push\PushSender;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\Concerns\EnablesPush;
use Tests\Fakes\FakePushSender;
use Tests\TestCase;

class PushSubscriptionTest extends TestCase
{
    use EnablesPush, RefreshDatabase;

    private const ENDPOINT = 'https://fcm.googleapis.com/fcm/send/device-1';

    public function test_the_pushes_are_off_by_default(): void
    {
        $this->setPushEnabled(false);
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNotFound();
        $this->assertSame(0, PushSubscription::count());
    }

    public function test_a_guest_cannot_subscribe(): void
    {
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertUnauthorized();
    }

    public function test_a_player_subscribes_a_device(): void
    {
        $player = User::factory()->create();
        Sanctum::actingAs($player);

        $this->postJson('/api/push-subscriptions', self::aSubscription(), ['Accept-Language' => 'en-GB,en;q=0.8'])->assertNoContent();

        $subscription = PushSubscription::sole();
        $this->assertSame($player->id, $subscription->user_id);
        $this->assertSame(self::ENDPOINT, $subscription->endpoint);
        $this->assertSame('en-GB,en;q=0.8', $subscription->accept_language);
    }

    public function test_a_device_subscribed_again_keeps_one_subscription_with_its_new_keys(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();
        $newKeys = self::aSubscription()['keys'];

        $this->postJson('/api/push-subscriptions', ['endpoint' => self::ENDPOINT, 'keys' => $newKeys])->assertNoContent();

        $this->assertSame($newKeys['auth'], PushSubscription::sole()->auth_token);
    }

    public function test_a_device_subscribed_by_another_player_goes_to_him(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();
        $nextPlayer = User::factory()->create();

        Sanctum::actingAs($nextPlayer);
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        $this->assertSame($nextPlayer->id, PushSubscription::sole()->user_id);
    }

    public function test_an_eleventh_device_takes_the_place_of_the_oldest_one(): void
    {
        Sanctum::actingAs(User::factory()->create());
        foreach (range(1, 10) as $device) {
            $this->travel(1)->minutes();
            $this->postJson('/api/push-subscriptions', self::aSubscription("https://fcm.googleapis.com/fcm/send/device-{$device}"))->assertNoContent();
        }

        $this->travel(1)->minutes();
        $this->postJson('/api/push-subscriptions', self::aSubscription('https://fcm.googleapis.com/fcm/send/device-11'))->assertNoContent();

        $this->assertSame(10, PushSubscription::count());
        $this->assertFalse(PushSubscription::where('endpoint', 'https://fcm.googleapis.com/fcm/send/device-1')->exists());
    }

    public static function invalidSubscriptions(): array
    {
        $valid = self::aSubscription();

        return [
            'nothing' => [[]],
            'no keys' => [['endpoint' => self::ENDPOINT]],
            'not https' => [[...$valid, 'endpoint' => 'http://fcm.googleapis.com/fcm/send/device-1']],
            'not a push service' => [[...$valid, 'endpoint' => 'https://169.254.169.254/latest/meta-data']],
            'a push service in the path only' => [[...$valid, 'endpoint' => 'https://evil.example/fcm.googleapis.com']],
            'a host ending like a push service' => [[...$valid, 'endpoint' => 'https://evilfcm.googleapis.com.example/send']],
            'too long' => [[...$valid, 'endpoint' => self::ENDPOINT.str_repeat('a', 500)]],
            'a public key not base64url' => [[...$valid, 'keys' => [...$valid['keys'], 'p256dh' => 'not base64!']]],
            'a public key of the wrong size' => [[...$valid, 'keys' => [...$valid['keys'], 'p256dh' => self::base64url(random_bytes(10))]]],
            'an auth secret of the wrong size' => [[...$valid, 'keys' => [...$valid['keys'], 'auth' => self::base64url(random_bytes(10))]]],
        ];
    }

    #[DataProvider('invalidSubscriptions')]
    public function test_an_invalid_subscription_is_refused(array $subscription): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/push-subscriptions', $subscription)->assertUnprocessable();
        $this->assertSame(0, PushSubscription::count());
    }

    public function test_the_push_services_of_the_browsers_are_accepted(): void
    {
        Sanctum::actingAs(User::factory()->create());

        foreach ([
            'https://fcm.googleapis.com/fcm/send/abc',
            'https://updates.push.services.mozilla.com/wpush/v2/abc',
            'https://web.push.apple.com/abc',
            'https://wns2-par02p.notify.windows.com/w/?token=abc',
        ] as $endpoint) {
            $this->postJson('/api/push-subscriptions', self::aSubscription($endpoint))->assertNoContent();
        }
        $this->assertSame(4, PushSubscription::count());
    }

    public function test_a_player_unsubscribes_his_device(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        $this->deleteJson('/api/push-subscriptions', ['endpoint' => self::ENDPOINT])->assertNoContent();

        $this->assertSame(0, PushSubscription::count());
    }

    public function test_a_player_cannot_unsubscribe_the_device_of_another_one(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        Sanctum::actingAs(User::factory()->create());
        $this->deleteJson('/api/push-subscriptions', ['endpoint' => self::ENDPOINT])->assertNoContent();

        $this->assertSame(1, PushSubscription::count());
    }

    public function test_the_device_is_unsubscribed_at_logout(): void
    {
        $player = User::factory()->create();
        Sanctum::actingAs($player);
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();
        $this->postJson('/api/push-subscriptions', self::aSubscription('https://fcm.googleapis.com/fcm/send/other-device'))->assertNoContent();

        $this->postJson('/api/logout', ['push_endpoint' => self::ENDPOINT])->assertNoContent();

        $this->assertSame(['https://fcm.googleapis.com/fcm/send/other-device'], PushSubscription::pluck('endpoint')->all());
    }

    public function test_a_player_sends_a_test_push_to_his_device(): void
    {
        $pushServices = $this->fakePushServices();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        $this->postJson('/api/push-subscriptions/test', ['endpoint' => self::ENDPOINT])->assertOk()->assertJsonPath('data.outcome', 'delivered');

        [$push] = $pushServices->deliveredTo(self::ENDPOINT);
        $this->assertTrue($push->payload()['test']);
    }

    public function test_a_test_push_to_a_device_gone_forgets_it(): void
    {
        $pushServices = $this->fakePushServices();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();
        $pushServices->answers(self::ENDPOINT, PushOutcome::GONE);

        $this->postJson('/api/push-subscriptions/test', ['endpoint' => self::ENDPOINT])->assertOk()->assertJsonPath('data.outcome', 'gone');

        $this->assertSame(0, PushSubscription::count());
    }

    public function test_a_player_cannot_send_a_test_push_to_the_device_of_another_one(): void
    {
        $pushServices = $this->fakePushServices();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions/test', ['endpoint' => self::ENDPOINT])->assertNotFound();

        $this->assertSame([], $pushServices->delivered);
    }

    public function test_the_test_pushes_are_limited(): void
    {
        $this->fakePushServices();
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/push-subscriptions', self::aSubscription())->assertNoContent();

        foreach (range(1, 3) as $try) {
            $this->postJson('/api/push-subscriptions/test', ['endpoint' => self::ENDPOINT])->assertOk();
        }
        $this->postJson('/api/push-subscriptions/test', ['endpoint' => self::ENDPOINT])->assertTooManyRequests();
    }

    private function fakePushServices(): FakePushSender
    {
        $pushServices = new FakePushSender();
        $this->app->instance(PushSender::class, $pushServices);

        return $pushServices;
    }

    private static function aSubscription(string $endpoint = self::ENDPOINT): array
    {
        return [
            'endpoint' => $endpoint,
            'expirationTime' => null,
            'keys' => [
                'p256dh' => self::base64url("\x04".random_bytes(64)),
                'auth' => self::base64url(random_bytes(16)),
            ],
        ];
    }

    private static function base64url(string $bytes): string
    {
        return rtrim(strtr(base64_encode($bytes), '+/', '-_'), '=');
    }
}
