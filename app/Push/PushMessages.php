<?php

namespace App\Push;

use App\Enums\NotificationType;
use App\Models\UserNotification;
use LogicException;

// the page it opens: the same as the link of the notification (resources/js/composables/useNotifications.js)
final class PushMessages
{
    public static function for(UserNotification $notification, string $locale): PushMessage
    {
        $game = $notification->run?->game?->name;
        $about = [
            'actor' => $notification->actor->display_name ?? __('server.push.a_player', locale: $locale),
            'of_game' => $game === null ? '' : __('server.push.of_game', ['game' => $game], $locale),
            'clan' => $notification->clan->name ?? '',
        ];
        [$title, $body] = match ($notification->type) {
            NotificationType::RUN_COMMENT => [__('server.push.run_comment.title', locale: $locale), __('server.push.run_comment.body', $about, $locale)],
            NotificationType::COMMENT_REPLY => [__('server.push.comment_reply.title', locale: $locale), __('server.push.comment_reply.body', $about, $locale)],
            NotificationType::CLAN_APPLICATION => [__('server.push.clan_application.title', locale: $locale), __('server.push.clan_application.body', $about, $locale)],
            NotificationType::CLAN_ACCEPTED => [__('server.push.clan_accepted.title', locale: $locale), __('server.push.clan_accepted.body', $about, $locale)],
            NotificationType::CLAN_REFUSED => [__('server.push.clan_refused.title', locale: $locale), __('server.push.clan_refused.body', $about, $locale)],
            NotificationType::COMMENT_LIKES => throw new LogicException('The likes do not interrupt the player: they have no push.'),
        };

        return PushMessage::ofNotification($notification->id, $title, $body, url: self::pageOf($notification));
    }

    public static function test(string $locale): PushMessage
    {
        return PushMessage::test(
            title: __('server.push.test.title', locale: $locale),
            body: __('server.push.test.body', locale: $locale),
            url: '/account/preferences',
        );
    }

    private static function pageOf(UserNotification $notification): string
    {
        return match ($notification->type) {
            NotificationType::RUN_COMMENT, NotificationType::COMMENT_REPLY, NotificationType::COMMENT_LIKES => "/runs/{$notification->run_id}?comment={$notification->comment_id}",
            NotificationType::CLAN_APPLICATION => "/clans/{$notification->clan_id}/manage",
            NotificationType::CLAN_ACCEPTED, NotificationType::CLAN_REFUSED => "/clans/{$notification->clan_id}",
        };
    }
}
