<?php

use Spatie\LaravelSettings\Migrations\SettingsMigration;

return new class() extends SettingsMigration
{
    public function up(): void
    {
        $this->migrator->add('site.announcement_enabled', true);
        $this->migrator->add('site.announcement_level', 'error');
        $this->migrator->add(
            'site.announcement_content',
            "Kadokadéo est en alpha! Il le restera jusqu'à avoir un site complet."
        );
    }

    public function down(): void
    {
        $this->migrator->delete('site.announcement_enabled');
        $this->migrator->delete('site.announcement_level');
        $this->migrator->delete('site.announcement_content');
    }
};
