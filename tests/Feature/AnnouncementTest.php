<?php

namespace Tests\Feature;

use App\Settings\SiteSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AnnouncementTest extends TestCase
{
    use RefreshDatabase;

    private function setAnnouncement(bool $enabled, ?string $content, string $level = 'error'): void
    {
        $settings = app(SiteSettings::class);
        $settings->announcement_enabled = $enabled;
        $settings->announcement_level = $level;
        $settings->announcement_content = $content;
        $settings->save();
    }

    public function test_it_returns_the_enabled_announcement_as_sanitized_html(): void
    {
        $this->setAnnouncement(true, "**Alpha** <script>alert(1)</script>\n[lien](javascript:alert(1))", 'success');

        $response = $this->getJson('/api/announcement')->assertOk();

        $this->assertSame('success', $response->json('data.level'));
        $html = $response->json('data.html');
        $this->assertStringContainsString('<strong>Alpha</strong>', $html);
        $this->assertStringContainsString('<br />', $html);
        $this->assertStringNotContainsString('<script>', $html);
        $this->assertStringNotContainsString('javascript:', $html);
    }

    public function test_it_returns_null_when_disabled_or_empty(): void
    {
        $this->setAnnouncement(false, 'Hidden');
        $this->getJson('/api/announcement')->assertOk()->assertExactJson(['data' => null]);

        $this->setAnnouncement(true, '   ');
        $this->getJson('/api/announcement')->assertOk()->assertExactJson(['data' => null]);
    }

    public function test_it_is_publicly_cacheable_with_an_etag(): void
    {
        $etag = $this->getJson('/api/announcement')->assertHeader('ETag')->headers->get('ETag');

        $this->getJson('/api/announcement', ['If-None-Match' => $etag])->assertStatus(304);
    }
}
