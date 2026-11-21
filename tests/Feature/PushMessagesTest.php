<?php

namespace Tests\Feature;

use App\Enums\NotificationType;
use App\Models\Clan;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use App\Models\UserNotification;
use App\Push\PushMessage;
use App\Push\PushMessages;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class PushMessagesTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        foreach (['fr' => 'FR', 'en' => 'EN'] as $locale => $mark) {
            app('translator')->addLines([
                'server.push.a_player' => "{$mark} someone",
                'server.push.of_game' => " {$mark} of :game",
                'server.push.run_comment.title' => "{$mark} comment",
                'server.push.run_comment.body' => "{$mark} :actor commented:of_game",
                'server.push.comment_reply.title' => "{$mark} reply",
                'server.push.comment_reply.body' => "{$mark} :actor replied:of_game",
                'server.push.clan_application.title' => "{$mark} application",
                'server.push.clan_application.body' => "{$mark} :actor applies to :clan",
                'server.push.clan_accepted.title' => "{$mark} accepted",
                'server.push.clan_accepted.body' => "{$mark} accepted in :clan",
                'server.push.clan_refused.title' => "{$mark} refused",
                'server.push.clan_refused.body' => "{$mark} refused by :clan",
            ], $locale);
        }
    }

    public static function interruptions(): array
    {
        return [
            'a comment on his replay' => [NotificationType::RUN_COMMENT, true],
            'a reply to his comment' => [NotificationType::COMMENT_REPLY, true],
            'the likes of his comment' => [NotificationType::COMMENT_LIKES, false],
            'an application to his clan' => [NotificationType::CLAN_APPLICATION, true],
            'his application accepted' => [NotificationType::CLAN_ACCEPTED, true],
            'his application refused' => [NotificationType::CLAN_REFUSED, true],
        ];
    }

    #[DataProvider('interruptions')]
    public function test_only_what_the_player_waits_for_interrupts_him(NotificationType $type, bool $interrupts): void
    {
        $this->assertSame($interrupts, $type->interruptsPlayer());
    }

    public function test_a_comment_on_his_replay_opens_the_comment(): void
    {
        $message = PushMessages::for($this->aNotification(NotificationType::RUN_COMMENT), 'fr');

        $this->assertSame(
            ['title' => 'FR comment', 'body' => 'FR Bob commented FR of Snake', 'url' => '/runs/run-1?comment=7', 'tag' => 'notification:42'],
            $message->payload(),
        );
    }

    public function test_a_reply_to_his_comment_opens_the_reply(): void
    {
        $message = PushMessages::for($this->aNotification(NotificationType::COMMENT_REPLY), 'fr');

        $this->assertSame('FR Bob replied FR of Snake', $message->body);
        $this->assertSame('/runs/run-1?comment=7', $message->url);
    }

    public function test_an_application_to_his_clan_opens_the_management_of_the_clan(): void
    {
        $message = PushMessages::for($this->aNotification(NotificationType::CLAN_APPLICATION), 'fr');

        $this->assertSame('FR Bob applies to Les Kados', $message->body);
        $this->assertSame('/clans/3/manage', $message->url);
    }

    public function test_his_application_answered_opens_the_clan(): void
    {
        $accepted = PushMessages::for($this->aNotification(NotificationType::CLAN_ACCEPTED), 'fr');
        $refused = PushMessages::for($this->aNotification(NotificationType::CLAN_REFUSED), 'fr');

        $this->assertSame(['FR accepted in Les Kados', '/clans/3'], [$accepted->body, $accepted->url]);
        $this->assertSame(['FR refused by Les Kados', '/clans/3'], [$refused->body, $refused->url]);
    }

    public function test_the_push_is_in_the_language_given(): void
    {
        $message = PushMessages::for($this->aNotification(NotificationType::RUN_COMMENT), 'en');

        $this->assertSame('EN comment', $message->title);
        $this->assertSame('EN Bob commented EN of Snake', $message->body);
    }

    public function test_a_player_whose_account_is_gone_is_someone(): void
    {
        $notification = $this->aNotification(NotificationType::RUN_COMMENT)->setRelation('actor', null);

        $this->assertSame('FR FR someone commented FR of Snake', PushMessages::for($notification, 'fr')->body);
    }

    public function test_a_replay_without_its_game_says_no_game(): void
    {
        $notification = $this->aNotification(NotificationType::RUN_COMMENT);
        $notification->run->setRelation('game', null);

        $this->assertSame('FR Bob commented', PushMessages::for($notification, 'fr')->body);
    }

    public function test_a_long_text_is_cut(): void
    {
        $notification = $this->aNotification(NotificationType::CLAN_APPLICATION);
        $notification->clan->name = str_repeat('é', 5000);

        $message = PushMessages::for($notification, 'fr');

        $this->assertLessThanOrEqual(PushMessage::MAX_BODY_LENGTH, mb_strlen($message->body));
        $this->assertLessThan(4096, strlen(json_encode($message->payload())));
    }

    public function test_a_test_push_says_it_is_one(): void
    {
        app('translator')->addLines(['server.push.test.title' => 'EN test', 'server.push.test.body' => 'EN it works'], 'en');

        $message = PushMessages::test('en');

        $this->assertSame(['title' => 'EN test', 'body' => 'EN it works', 'url' => '/account/preferences', 'tag' => 'test', 'test' => true], $message->payload());
    }

    public function test_the_payload_is_what_the_service_worker_reads(): void
    {
        $message = PushMessage::ofNotification(1, title: 'A title', body: 'A body', url: '/runs/1');

        $this->assertSame(['title' => 'A title', 'body' => 'A body', 'url' => '/runs/1', 'tag' => 'notification:1'], $message->payload());
    }

    private function aNotification(NotificationType $type): UserNotification
    {
        $notification = new UserNotification(['type' => $type, 'run_id' => 'run-1', 'comment_id' => 7, 'clan_id' => 3]);
        $notification->id = 42;
        $run = (new Run())->forceFill(['id' => 'run-1'])->setRelation('game', (new Game())->forceFill(['name' => 'Snake']));

        return $notification
            ->setRelation('actor', (new User())->forceFill(['display_name' => 'Bob']))
            ->setRelation('run', $run)
            ->setRelation('clan', (new Clan())->forceFill(['id' => 3, 'name' => 'Les Kados']));
    }
}
