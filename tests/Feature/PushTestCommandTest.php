<?php

namespace Tests\Feature;

use App\Models\PushSubscription;
use App\Models\User;
use App\Push\PushOutcome;
use App\Push\PushSender;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Fakes\FakePushSender;
use Tests\TestCase;

class PushTestCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_each_device_of_the_player_gets_a_push_and_its_answer_is_shown(): void
    {
        $pushServices = new FakePushSender();
        $this->app->instance(PushSender::class, $pushServices);
        $player = User::factory()->create();
        foreach (['phone', 'computer'] as $device) {
            PushSubscription::query()->create(['user_id' => $player->id, 'endpoint' => "https://fcm.googleapis.com/fcm/send/{$device}", 'public_key' => 'key', 'auth_token' => 'secret']);
        }
        $pushServices->answers('https://fcm.googleapis.com/fcm/send/computer', PushOutcome::REJECTED);

        $this->artisan('kado:push-test', ['user' => $player->id])
            ->expectsOutputToContain('https://fcm.googleapis.com/fcm/send/phone: DELIVERED')
            ->expectsOutputToContain('https://fcm.googleapis.com/fcm/send/computer: REJECTED')
            ->assertSuccessful();

        $this->assertCount(1, $pushServices->deliveredTo('https://fcm.googleapis.com/fcm/send/phone'));
    }

    public function test_a_player_without_devices_is_said_so(): void
    {
        $this->artisan('kado:push-test', ['user' => User::factory()->create()->id])->assertFailed();
    }
}
