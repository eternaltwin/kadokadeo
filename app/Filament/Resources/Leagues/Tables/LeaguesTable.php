<?php

namespace App\Filament\Resources\Leagues\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class LeaguesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('level')
                    ->label('Niveau')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('name')
                    ->label('Nom')
                    ->searchable(),
                TextColumn::make('promotion_max_slots')
                    ->label('Places de promotion max')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('promotion_ratio_divisor')
                    ->label('Diviseur du ratio de promotion')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('promotion_min_stars')
                    ->label('Étoiles min. pour la promotion')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('promotion_reward')
                    ->label('Récompense de promotion')
                    ->numeric()
                    ->sortable(),
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
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
