<?php

namespace Tests\Feature;

use App\Enums\ClanRole;
use App\Enums\LocalePreference;
use App\Enums\UserPreference;
use App\Models\Clan;
use App\Models\Period;
use App\Models\PushSubscription;
use App\Models\Run;
use App\Models\RunComment;
use App\Models\User;
use App\Models\UserNotification;
use App\Push\PushOutcome;
use App\Push\PushSender;
use App\Services\NotificationService;
use App\Settings\SiteSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use RuntimeException;
use Tests\Concerns\EnablesClans;
use Tests\Concerns\EnablesPush;
use Tests\Fakes\FakePushSender;
use Tests\TestCase;

class PushNotificationTest extends TestCase
{
    use EnablesClans, EnablesPush, RefreshDatabase;

    private FakePushSender $pushServices;

    protected function setUp(): void
    {
        parent::setUp();
        config(['queue.default' => 'database']);
        $this->pushServices = new FakePushSender();
        $this->app->instance(PushSender::class, $this->pushServices);
        app('translator')->addLines([
            'server.push.run_comment.body' => 'FR :actor commented',
            'server.push.clan_application.body' => 'FR :actor applies',
        ], 'fr');
        app('translator')->addLines(['server.push.run_comment.body' => 'EN :actor commented'], 'en');
    }

    public function test_a_comment_on_his_replay_goes_to_each_of_his_devices(): void
    {
        $player = $this->aPlayerWithDevices('phone', 'computer');
        $commenter = User::factory()->create(['display_name' => 'Bob']);

        $this->comment($commenter, $this->aRunOf($player));
        $this->deliverPushes();

        $notification = UserNotification::sole();
        foreach (['phone', 'computer'] as $device) {
            $this->assertCount(1, $this->pushServices->deliveredTo($this->endpoint($device)));
            $push = $this->pushServices->deliveredTo($this->endpoint($device))[0];
            $this->assertSame('FR Bob commented', $push->body);
            $this->assertSame("notification:{$notification->id}", $push->tag);
        }
    }

    public function test_a_player_without_devices_gets_no_push(): void
    {
        $player = User::factory()->create();

        $this->comment(User::factory()->create(), $this->aRunOf($player));

        $this->assertSame(1, UserNotification::count());
        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_what_does_not_notify_does_not_push(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $run = $this->aRunOf($player);

        $this->comment($player, $run);
        $player->update(['preferences' => [UserPreference::NOTIFY_RUN_COMMENTS->value => false]]);
        $this->comment(User::factory()->create(), $run);

        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_the_likes_do_not_push(): void
    {
        $commenter = $this->aPlayerWithDevices('phone');
        $comment = $this->comment($commenter, $this->aRunOf(User::factory()->create()));

        Sanctum::actingAs(User::factory()->create());
        $this->putJson("/api/run-comments/{$comment}/like")->assertSuccessful();

        $this->assertSame(['comment_likes'], UserNotification::query()->where('user_id', $commenter->id)->pluck('type')->map->value->all());
        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_an_application_goes_to_the_leader_and_the_right_hands(): void
    {
        Period::factory()->create(['start_at' => now()->subDay()->startOfDay(), 'end_at' => now()->addDays(12)->endOfDay()]);
        $leader = $this->aPlayerWithDevices('leader');
        $clan = Clan::factory()->withLeader($leader)->create();
        foreach (['right-hand-1', 'right-hand-2'] as $device) {
            $clan->members()->create(['user_id' => $this->aPlayerWithDevices($device)->id, 'role' => ClanRole::RIGHT_HAND]);
        }

        Sanctum::actingAs(User::factory()->create(['kado_points' => 1000, 'display_name' => 'Alice']));
        $this->postJson("/api/clans/{$clan->id}/applications")->assertCreated();
        $this->deliverPushes();

        foreach (['leader', 'right-hand-1', 'right-hand-2'] as $device) {
            $this->assertSame(['FR Alice applies'], array_map(fn ($push) => $push->body, $this->pushServices->deliveredTo($this->endpoint($device))));
        }
    }

    public function test_the_push_is_written_with_its_notification_or_not_at_all(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $comment = RunComment::factory()->for(User::factory()->create())->create(['run_id' => $this->aRunOf($player)->id]);

        try {
            DB::transaction(function () use ($comment) {
                app(NotificationService::class)->commentCreated($comment);
                throw new RuntimeException('the comment could not be saved');
            });
        } catch (RuntimeException) {
        }

        $this->assertSame(0, UserNotification::count());
        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_a_comment_deleted_before_its_push_is_not_pushed(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $commenter = User::factory()->create();
        $comment = $this->comment($commenter, $this->aRunOf($player));

        Sanctum::actingAs($commenter);
        $this->deleteJson("/api/run-comments/{$comment}")->assertSuccessful();
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->deliveredTo($this->endpoint('phone')));
    }

    public function test_a_notification_read_before_its_push_is_not_pushed(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $this->comment(User::factory()->create(), $this->aRunOf($player));

        app(NotificationService::class)->markAllRead($player);
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->deliveredTo($this->endpoint('phone')));
    }

    public function test_a_player_gone_before_his_push_is_not_pushed(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $this->comment(User::factory()->create(), $this->aRunOf($player));

        $player->delete();
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->delivered);
        $this->assertSame(0, DB::table('failed_jobs')->count());
    }

    public function test_a_device_gone_to_another_player_before_the_push_is_not_pushed(): void
    {
        $player = $this->aPlayerWithDevices('shared-tablet');
        $this->comment(User::factory()->create(), $this->aRunOf($player));

        PushSubscription::query()->update(['user_id' => User::factory()->create()->id]);
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->delivered);
    }

    public function test_a_device_gone_from_its_push_service_is_forgotten_without_stopping_the_others(): void
    {
        $player = $this->aPlayerWithDevices('old-phone', 'computer');
        $this->pushServices->answers($this->endpoint('old-phone'), PushOutcome::GONE);

        $this->comment(User::factory()->create(), $this->aRunOf($player));
        $this->deliverPushes();

        $this->assertSame([$this->endpoint('computer')], PushSubscription::pluck('endpoint')->all());
        $this->assertCount(1, $this->pushServices->deliveredTo($this->endpoint('computer')));
    }

    public function test_a_push_service_down_is_tried_again_later(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $this->pushServices->answers($this->endpoint('phone'), PushOutcome::RETRY, PushOutcome::RETRY);

        $this->comment(User::factory()->create(), $this->aRunOf($player));
        $this->deliverPushes();
        $this->travel(1)->minute();
        $this->deliverPushes();
        $this->assertSame([], $this->pushServices->deliveredTo($this->endpoint('phone')));

        $this->travel(5)->minutes();
        $this->deliverPushes();

        $this->assertCount(1, $this->pushServices->deliveredTo($this->endpoint('phone')));
        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_a_push_service_down_for_hours_drops_the_push(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $this->pushServices->answers($this->endpoint('phone'), ...array_fill(0, 10, PushOutcome::RETRY));

        $this->comment(User::factory()->create(), $this->aRunOf($player));
        foreach ([0, 1, 5, 30, 120] as $minutes) {
            $this->travel($minutes)->minutes();
            $this->deliverPushes();
        }

        $this->assertSame([], $this->pushServices->deliveredTo($this->endpoint('phone')));
        $this->assertSame(0, DB::table('jobs')->count());
        $this->assertSame(1, DB::table('failed_jobs')->count());
    }

    public function test_a_push_refused_is_not_tried_again_and_the_device_is_kept(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $this->pushServices->answers($this->endpoint('phone'), PushOutcome::REJECTED, PushOutcome::DELIVERED);

        $this->comment(User::factory()->create(), $this->aRunOf($player));
        $this->deliverPushes();
        $this->travel(1)->hour();
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->deliveredTo($this->endpoint('phone')));
        $this->assertSame(1, DB::table('failed_jobs')->count());
        $this->assertSame(1, PushSubscription::count());
    }

    public function test_the_pushes_turned_off_send_nothing_even_the_ones_waiting(): void
    {
        $player = $this->aPlayerWithDevices('phone');
        $run = $this->aRunOf($player);
        $this->comment(User::factory()->create(), $run);

        $this->setPushEnabled(false);
        $this->comment(User::factory()->create(), $run);
        $this->deliverPushes();

        $this->assertSame([], $this->pushServices->delivered);
        $this->assertSame(0, DB::table('jobs')->count());
    }

    public function test_the_push_is_in_the_language_of_the_player(): void
    {
        $this->setLanguagesEnabled(true);
        $player = $this->aPlayerWithDevices('phone');
        $player->update(['locale' => LocalePreference::EN]);

        $this->comment(User::factory()->create(['display_name' => 'Bob']), $this->aRunOf($player));
        $this->deliverPushes();

        $this->assertSame('EN Bob commented', $this->pushServices->deliveredTo($this->endpoint('phone'))[0]->body);
    }

    public function test_a_player_in_the_language_of_his_browser_gets_the_language_of_his_device(): void
    {
        $this->setLanguagesEnabled(true);
        $player = $this->aPlayerWithDevices('phone');
        PushSubscription::query()->update(['accept_language' => 'en-US,en;q=0.9']);

        $this->comment(User::factory()->create(['display_name' => 'Bob']), $this->aRunOf($player));
        $this->deliverPushes();

        $this->assertSame('EN Bob commented', $this->pushServices->deliveredTo($this->endpoint('phone'))[0]->body);
    }

    private function aPlayerWithDevices(string ...$devices): User
    {
        $player = User::factory()->create();
        foreach ($devices as $device) {
            PushSubscription::query()->create([
                'user_id' => $player->id,
                'endpoint' => $this->endpoint($device),
                'public_key' => 'public-key',
                'auth_token' => 'auth-token',
            ]);
        }

        return $player;
    }

    private function endpoint(string $device): string
    {
        return "https://fcm.googleapis.com/fcm/send/{$device}";
    }

    private function aRunOf(User $player): Run
    {
        return Run::factory()->for($player)->create(['replay' => 'replay-data', 'replay_frames' => 3200]);
    }

    private function comment(User $author, Run $run): int
    {
        Sanctum::actingAs($author);

        return $this->postJson("/api/runs/{$run->id}/comments", ['frame' => 64, 'content' => 'Joli coup'])->assertCreated()->json('data.id');
    }

    // (the whole suite is over the 128 MB at which a worker stops after its job)
    private function deliverPushes(): void
    {
        Artisan::call('queue:work', ['connection' => 'database', '--stop-when-empty' => true, '--memory' => PHP_INT_MAX]);
    }

    private function setLanguagesEnabled(bool $enabled): void
    {
        $settings = app(SiteSettings::class);
        $settings->i18n_enabled = $enabled;
        $settings->save();
    }
}
