<?php

namespace Tests\Feature;

use App\Settings\SiteSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnnouncementTest extends TestCase
{
    use RefreshDatabase;

    /** @param array<string, ?string> $contents the text of each language */
    private function setAnnouncement(bool $enabled, array $contents, string $level = 'error'): void
    {
        $settings = app(SiteSettings::class);
        $settings->announcement_enabled = $enabled;
        $settings->announcement_level = $level;
        $settings->announcement_contents = $contents;
        $settings->save();
    }

    public function test_it_returns_the_enabled_announcement_as_sanitized_html(): void
    {
        $this->setAnnouncement(true, ['fr' => "**Alpha** <script>alert(1)</script>\n[lien](javascript:alert(1))"], 'success');

        $response = $this->getJson('/api/announcement')->assertOk();

        $this->assertSame('success', $response->json('data.level'));
        $html = $response->json('data.html.fr');
        $this->assertStringContainsString('<strong>Alpha</strong>', $html);
        $this->assertStringContainsString('<br />', $html);
        $this->assertStringNotContainsString('<script>', $html);
        $this->assertStringNotContainsString('javascript:', $html);
    }

    public function test_it_returns_null_when_disabled_or_empty(): void
    {
        $this->setAnnouncement(false, ['fr' => 'Hidden']);
        $this->getJson('/api/announcement')->assertOk()->assertExactJson(['data' => null]);

        $this->setAnnouncement(true, ['fr' => '   ']);
        $this->getJson('/api/announcement')->assertOk()->assertExactJson(['data' => null]);
    }

    public function test_it_gives_the_text_of_every_language(): void
    {
        $this->setAnnouncement(true, ['fr' => 'Bonjour', 'en' => 'Hello']);

        $this->getJson('/api/announcement')->assertOk()->assertJsonPath('data.html', [
            'fr' => "Bonjour\n",
            'en' => "Hello\n",
        ]);
    }

    // the page shows the French one
    public function test_a_language_without_text_is_left_out(): void
    {
        $this->setAnnouncement(true, ['fr' => 'Bonjour', 'en' => '  ']);

        $this->getJson('/api/announcement')->assertOk()->assertJsonPath('data.html', ['fr' => "Bonjour\n"]);
    }

    public function test_there_is_no_announcement_without_its_french_text(): void
    {
        $this->setAnnouncement(true, ['fr' => '', 'en' => 'Hello']);

        $this->getJson('/api/announcement')->assertOk()->assertExactJson(['data' => null]);
    }

    public function test_the_text_of_another_language_is_sanitized_too(): void
    {
        $this->setAnnouncement(true, ['fr' => 'Bonjour', 'en' => '<script>alert(1)</script> **x**']);

        $html = $this->getJson('/api/announcement')->assertOk()->json('data.html.en');

        $this->assertStringContainsString('<strong>x</strong>', $html);
        $this->assertStringNotContainsString('<script>', $html);
    }

    // publicly cached: a shared cache gives the same answer to every language
    public function test_the_answer_does_not_depend_on_the_language_of_the_player(): void
    {
        $this->setSettings(SiteSettings::class, ['i18n_enabled' => true]);
        $this->setAnnouncement(true, ['fr' => 'Bonjour', 'en' => 'Hello']);

        $french = $this->getJson('/api/announcement', ['Accept-Language' => 'fr'])->json();
        $english = $this->getJson('/api/announcement', ['Accept-Language' => 'en'])->json();

        $this->assertSame($french, $english);
    }

    public function test_it_is_publicly_cacheable_with_an_etag(): void
    {
        $etag = $this->getJson('/api/announcement')->assertHeader('ETag')->headers->get('ETag');

        $this->getJson('/api/announcement', ['If-None-Match' => $etag])->assertStatus(304);
    }
}
