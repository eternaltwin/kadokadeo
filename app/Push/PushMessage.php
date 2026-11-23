<?php

namespace App\Push;

use Illuminate\Support\Str;

final readonly class PushMessage
{
    // the push services refuse a payload over 4 KB, encrypted: a long name of clan or of player is cut
    public const MAX_TITLE_LENGTH = 100;

    public const MAX_BODY_LENGTH = 300;

    public string $title;

    public string $body;

    private function __construct(string $title, string $body, public string $url, public string $tag, private bool $isTest)
    {
        $this->title = Str::limit($title, self::MAX_TITLE_LENGTH - 1, '…');
        $this->body = Str::limit($body, self::MAX_BODY_LENGTH - 1, '…');
    }

    public static function ofNotification(int $notificationId, string $title, string $body, string $url): self
    {
        return new self($title, $body, $url, tag: "notification:{$notificationId}", isTest: false);
    }

    // shown even over the site: the player is looking for it
    public static function test(string $title, string $body, string $url): self
    {
        return new self($title, $body, $url, tag: 'test', isTest: true);
    }

    /** @return array{title: string, body: string, url: string, tag: string, test?: true} */
    public function payload(): array
    {
        $payload = ['title' => $this->title, 'body' => $this->body, 'url' => $this->url, 'tag' => $this->tag];

        return $this->isTest ? [...$payload, 'test' => true] : $payload;
    }
}
