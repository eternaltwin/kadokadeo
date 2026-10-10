<?php

namespace App\Filament\Pages;

use App\Settings\ClanSettings;
use BackedEnum;
use Filament\Forms\Components\TextInput;
use Filament\Pages\SettingsPage;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use UnitEnum;

class ManageClanSettings extends SettingsPage
{
    protected static string $settings = ClanSettings::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUserGroup;

    protected static string|UnitEnum|null $navigationGroup = 'Paramètres';

    protected static ?string $navigationLabel = 'Clans';

    protected static ?string $title = 'Paramètres des clans';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Attaques et défenses')
                    ->description('Les missions sont gratuites et illimitées. Les attaques et les défenses utilisent ces parties, puis les parties de clan achetées avec des points Kado.')
                    ->schema([
                        TextInput::make('attack_games_per_day')
                            ->label('Parties d\'attaque et de défense par jour')
                            ->helperText('Données à chaque joueur tous les jours (remise à zéro quotidienne des parties).')
                            ->required()
                            ->integer()
                            ->minValue(0),
                    ]),
            ]);
    }
}
