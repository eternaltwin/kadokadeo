<?php

use Spatie\LaravelSettings\Migrations\SettingsMigration;

// the announcement is written in each language of the site: the text of before is the French one
return new class() extends SettingsMigration
{
    public function up(): void
    {
        $this->migrator->rename('site.announcement_content', 'site.announcement_contents');
        $this->migrator->update('site.announcement_contents', fn (?string $french) => ['fr' => $french]);
    }

    public function down(): void
    {
        $this->migrator->update('site.announcement_contents', fn (array|object $contents) => ((array) $contents)['fr'] ?? null);
        $this->migrator->rename('site.announcement_contents', 'site.announcement_content');
    }
};
