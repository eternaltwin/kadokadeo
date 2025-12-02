<?php

namespace App\Filament\Resources\Games\RelationManagers;

use App\Enums\ControlKey;
use App\Filament\Resources\Games\GameResource;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TagsInput;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables\Table;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;

class ControlsRelationManager extends RelationManager
{
    protected static string $relationship = 'controls';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('description')->required(),
                TextInput::make('order')->required(),
                Select::make('keys')->options(ControlKey::class)->multiple()->required(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')
                    ->label('ID'),
                TextColumn::make('description'),
                TextColumn::make('order'),
                TextColumn::make('keys')
                    ->label('Keys')
                    ->bulleted(ControlKey::class),
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                DeleteAction::make(),
                EditAction::make(),
            ]);
    }
}
