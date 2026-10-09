<?php

namespace App\Filament\Resources\Clans\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class ClanForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->label('Nom')
                    ->required()
                    ->maxLength(32)
                    ->unique(ignoreRecord: true),
                Select::make('leader_id')
                    ->label('Chef de clan')
                    ->relationship('leader', 'display_name', fn ($query, $record) => $query->whereHas('clanMember', fn ($q) => $q->where('clan_id', $record?->id)))
                    ->searchable()
                    ->preload(),
                Toggle::make('is_recruiting')
                    ->label('Recrute'),
                Textarea::make('description')
                    ->label('Présentation')
                    ->rows(8)
                    ->columnSpanFull(),
            ]);
    }
}
