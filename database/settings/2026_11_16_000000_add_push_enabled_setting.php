<?php

use Spatie\LaravelSettings\Migrations\SettingsMigration;

return new class() extends SettingsMigration
{
    public function up(): void
    {
        // off: no device can subscribe to the pushes and none is sent
        $this->migrator->add('site.push_enabled', false);
    }

    public function down(): void
    {
        $this->migrator->delete('site.push_enabled');
    }
};
