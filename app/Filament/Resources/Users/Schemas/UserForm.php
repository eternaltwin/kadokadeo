<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('etwin_id')
                    ->required(),
                TextInput::make('display_name')
                    ->required(),
                TextInput::make('kado_points')
                    ->required()
                    ->numeric()
                    ->default(0),
                TextInput::make('kado_games')
                    ->required()
                    ->numeric(),
                TextInput::make('email')
                    ->label('Email address')
                    ->email(),
                TextInput::make('password')
                    ->password()
                    ->dehydrated(fn ($state) => filled($state)),
                DateTimePicker::make('last_seen_at'),
                Toggle::make('is_admin')
                    ->required(),
            ]);
    }
}
