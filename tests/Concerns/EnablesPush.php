<?php

namespace Tests\Concerns;

use App\Settings\SiteSettings;

trait EnablesPush
{
    protected function setUpEnablesPush(): void
    {
        $this->setPushEnabled(true);
    }

    protected function setPushEnabled(bool $enabled): void
    {
        $settings = app(SiteSettings::class);
        $settings->push_enabled = $enabled;
        $settings->save();
    }
}
