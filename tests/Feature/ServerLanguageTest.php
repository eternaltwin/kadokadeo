<?php

namespace Tests\Feature;

use App\Enums\LocalePreference;
use App\Models\User;
use App\Settings\SiteSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class ServerLanguageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        app('translator')->addLines(['server.demo.hello' => 'Bonjour :name', 'server.demo.only_french' => 'Texte français'], 'fr');
        app('translator')->addLines(['server.demo.hello' => 'Hello :name'], 'en');
        Route::middleware('api')->get('/api/test-language', fn () => [
            'hello' => __('server.demo.hello', ['name' => 'Mel']),
            'only_french' => __('server.demo.only_french'),
            'validation' => __('validation.required', ['attribute' => 'nom']),
        ]);
        Route::middleware('web')->get('/test-language-web', fn () => ['hello' => __('server.demo.hello', ['name' => 'Mel'])]);
    }

    private function languagesOn(): void
    {
        $this->setSettings(SiteSettings::class, ['i18n_enabled' => true]);
    }

    private function askInEnglish(string $url = '/api/test-language')
    {
        return $this->withHeader('Accept-Language', 'en')->getJson($url);
    }

    public function test_with_the_languages_off_the_api_answers_in_french(): void
    {
        $this->askInEnglish()->assertJsonPath('hello', 'Bonjour Mel');
    }

    public function test_the_api_answers_in_the_language_of_the_browser(): void
    {
        $this->languagesOn();

        $this->askInEnglish()->assertJsonPath('hello', 'Hello Mel');
    }

    public function test_the_api_answers_in_the_language_of_the_account(): void
    {
        $this->languagesOn();
        $this->actingAs(User::factory()->create(['locale' => LocalePreference::FR]), 'web');

        $this->withHeader('Referer', config('app.url'))->askInEnglish()->assertJsonPath('hello', 'Bonjour Mel');
    }

    public function test_a_text_without_a_translation_is_french_never_its_key(): void
    {
        $this->languagesOn();

        $this->askInEnglish()->assertJsonPath('only_french', 'Texte français');
    }

    public function test_what_is_not_the_api_keeps_its_language(): void
    {
        $this->languagesOn();

        $this->withHeader('Accept-Language', 'en')->get('/test-language-web')->assertJsonPath('hello', 'Bonjour Mel');
    }

    public function test_the_admin_panel_stays_in_french_for_an_english_admin(): void
    {
        $this->languagesOn();
        $this->actingAs(User::factory()->create(['is_admin' => true, 'locale' => LocalePreference::EN]), 'web');

        $this->withHeader('Accept-Language', 'en')->get('/admin')->assertOk()->assertSee('<html', false)->assertSee('lang="fr"', false);
    }

    public function test_a_rule_without_its_own_message_is_readable_in_french(): void
    {
        $this->getJson('/api/test-language')->assertJsonPath('validation', 'Le champ nom est obligatoire.');
    }

    public function test_a_rule_without_its_own_message_is_readable_in_english(): void
    {
        $this->languagesOn();

        $this->askInEnglish()->assertJsonPath('validation', 'The nom field is required.');
    }

    public function test_a_catalog_of_the_server_is_read_from_its_json(): void
    {
        $this->assertIsArray(require resource_path('lang/fr/server.php'));
        $this->assertSame(
            json_decode(file_get_contents(resource_path('lang/en/server.json')), true),
            require resource_path('lang/en/server.php'),
        );
    }
}
