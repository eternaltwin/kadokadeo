<?php

namespace Tests\Unit;

use App\Enums\LocalePreference;
use App\Support\LocaleResolver;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

class LocaleResolverTest extends TestCase
{
    private function language(
        bool $enabled = true,
        LocalePreference $account = LocalePreference::AUTO,
        ?string $cookie = null,
        ?string $browser = null,
    ): string {
        return LocaleResolver::resolve($enabled, $account, $cookie, $browser);
    }

    public function test_the_flag_off_means_french_whatever_was_chosen(): void
    {
        $this->assertSame('fr', $this->language(enabled: false, account: LocalePreference::EN, cookie: 'en', browser: 'en'));
    }

    public function test_the_account_wins_over_the_cookie_and_the_browser(): void
    {
        $this->assertSame('fr', $this->language(account: LocalePreference::FR, cookie: 'en', browser: 'en'));
        $this->assertSame('en', $this->language(account: LocalePreference::EN, cookie: 'fr', browser: 'fr'));
    }

    public function test_an_automatic_account_follows_the_cookie(): void
    {
        $this->assertSame('en', $this->language(cookie: 'en', browser: 'fr'));
    }

    public function test_an_automatic_cookie_or_an_unknown_one_lets_the_browser_decide(): void
    {
        $this->assertSame('en', $this->language(cookie: 'auto', browser: 'en'));
        $this->assertSame('en', $this->language(cookie: 'klingon', browser: 'en'));
        $this->assertSame('en', $this->language(cookie: '', browser: 'en'));
    }

    #[DataProvider('browserLanguages')]
    public function test_the_browser_decides_last(?string $browser, string $expected): void
    {
        $this->assertSame($expected, $this->language(browser: $browser));
    }

    /** @return array<string, array{?string, string}> */
    public static function browserLanguages(): array
    {
        return [
            'French' => ['fr', 'fr'],
            'a region' => ['en-GB', 'en'],
            'another case' => ['EN-gb', 'en'],
            'the first one supported' => ['es, en-GB;q=0.8, fr;q=0.5', 'en'],
            'the weights decide, not the order' => ['fr;q=0.5, en;q=0.9', 'en'],
            'a refused language' => ['en;q=0, fr;q=0.5', 'fr'],
            'only refused languages' => ['en;q=0', 'fr'],
            'a language not supported: French during the beta' => ['de', 'fr'],
            'any language' => ['*', 'fr'],
            'no header' => [null, 'fr'],
            'an empty header' => ['', 'fr'],
            'a broken header' => [';;;=,,q=x', 'fr'],
        ];
    }

    public function test_a_huge_header_changes_nothing(): void
    {
        $this->assertSame('fr', $this->language(browser: str_repeat('xx-YY,', 2000)));
    }

    public function test_the_login_gives_the_cookie_to_an_automatic_account(): void
    {
        $this->assertSame(LocalePreference::EN, LocaleResolver::preferenceAtLogin(true, LocalePreference::AUTO, 'en'));
    }

    public function test_the_login_keeps_a_chosen_language(): void
    {
        $this->assertSame(LocalePreference::FR, LocaleResolver::preferenceAtLogin(true, LocalePreference::FR, 'en'));
    }

    #[DataProvider('cookiesWithoutChoice')]
    public function test_the_login_ignores_a_cookie_without_a_choice(?string $cookie): void
    {
        $this->assertSame(LocalePreference::AUTO, LocaleResolver::preferenceAtLogin(true, LocalePreference::AUTO, $cookie));
    }

    /** @return array<string, array{?string}> */
    public static function cookiesWithoutChoice(): array
    {
        return ['none' => [null], 'automatic' => ['auto'], 'unknown' => ['klingon'], 'empty' => ['']];
    }

    public function test_the_login_changes_nothing_with_the_flag_off(): void
    {
        $this->assertSame(LocalePreference::AUTO, LocaleResolver::preferenceAtLogin(false, LocalePreference::AUTO, 'en'));
    }
}
