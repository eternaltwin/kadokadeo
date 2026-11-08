<?php

namespace App\Support;

use App\Enums\LocalePreference;
use App\Models\User;
use App\Settings\SiteSettings;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\AcceptHeader;

// The language of a page: the choice of the account, then the cookie, then the browser. Only the page follows it:
// the API and the admin panel never change their language, so app()->setLocale() is not called.
final class LocaleResolver
{
    // written by the page (resources/js/i18n/localeChoice.js): not encrypted
    public const COOKIE = 'kado_locale';

    // the texts are written in French: the language of the site when the languages are off
    private const SOURCE_LANGUAGE = 'fr';

    private const SUPPORTED_LANGUAGES = ['fr', 'en'];

    // French while English is in beta
    private const LANGUAGE_OF_OTHER_BROWSERS = 'fr';

    public static function forRequest(Request $request): string
    {
        $enabled = app(SiteSettings::class)->i18n_enabled;
        if (!$enabled) {
            return self::SOURCE_LANGUAGE;
        }
        /** @var User|null $player */
        $player = $request->user('web');

        return self::resolve(
            $enabled,
            $player->locale ?? LocalePreference::AUTO,
            $request->cookie(self::COOKIE),
            $request->header('Accept-Language'),
        );
    }

    public static function resolve(bool $enabled, LocalePreference $account, ?string $cookie, ?string $acceptLanguage): string
    {
        if (!$enabled) {
            return self::SOURCE_LANGUAGE;
        }
        if ($account !== LocalePreference::AUTO) {
            return $account->value;
        }
        if (self::isSupported($cookie)) {
            return $cookie;
        }

        return self::browserLanguage($acceptLanguage) ?? self::LANGUAGE_OF_OTHER_BROWSERS;
    }

    public static function preferenceAtLogin(bool $enabled, LocalePreference $account, ?string $cookie): LocalePreference
    {
        $visitorChoseALanguage = $enabled && $account === LocalePreference::AUTO && self::isSupported($cookie);

        return $visitorChoseALanguage ? LocalePreference::from($cookie) : $account;
    }

    private static function isSupported(?string $language): bool
    {
        return in_array($language, self::SUPPORTED_LANGUAGES, true);
    }

    private static function browserLanguage(?string $acceptLanguage): ?string
    {
        foreach (AcceptHeader::fromString($acceptLanguage ?? '')->all() as $accepted) {
            $language = strtolower(explode('-', $accepted->getValue())[0]);
            if ($accepted->getQuality() > 0 && self::isSupported($language)) {
                return $language;
            }
        }

        return null;
    }
}
