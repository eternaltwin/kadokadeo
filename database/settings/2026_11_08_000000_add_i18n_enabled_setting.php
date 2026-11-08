<?php

use Spatie\LaravelSettings\Migrations\SettingsMigration;

return new class() extends SettingsMigration
{
    public function up(): void
    {
        // off: the whole site is in French and the choice of the language is hidden
        $this->migrator->add('site.i18n_enabled', false);
    }

    public function down(): void
    {
        $this->migrator->delete('site.i18n_enabled');
    }
};
