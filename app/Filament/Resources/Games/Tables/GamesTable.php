<?php

namespace App\Filament\Resources\Games\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class GamesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                ImageColumn::make('image_path')
                    ->label('Image')
                    ->state(fn ($record) => config('app.url').$record->image_path)
                    ->checkFileExistence(false),
                TextColumn::make('name')
                    ->label('Nom')
                    ->searchable(),
                TextColumn::make('category_id')
                    ->label('Catégorie')
                    ->getStateUsing(fn ($record) => $record->category?->name ?? 'Sans catégorie'),
                IconColumn::make('is_active')
                    ->label('Actif')
                    ->boolean(),
                IconColumn::make('is_arkadeo')
                    ->label('Jeu Arkadéo')
                    ->boolean(),
                TextColumn::make('created_at')
                    ->label('Créé le')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('updated_at')
                    ->label('Modifié le')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                ViewAction::make(),
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
