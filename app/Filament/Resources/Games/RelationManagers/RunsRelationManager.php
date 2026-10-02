<?php

namespace App\Filament\Resources\Games\RelationManagers;

use Filament\Actions\AssociateAction;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\DissociateAction;
use Filament\Actions\DissociateBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\ForceDeleteAction;
use Filament\Actions\ForceDeleteBulkAction;
use Filament\Actions\RestoreAction;
use Filament\Actions\RestoreBulkAction;
use Filament\Forms\Components\Checkbox;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\TrashedFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class RunsRelationManager extends RelationManager
{
    protected static string $relationship = 'runs';

    protected static ?string $title = 'Parties';

    protected static ?string $modelLabel = 'partie';

    protected static ?string $pluralModelLabel = 'parties';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('period_id')
                    ->label('Période')
                    ->numeric(),
                TextInput::make('user_id')
                    ->label('ID utilisateur')
                    ->required()
                    ->numeric(),
                TextInput::make('contract_score')
                    ->label('Score du contrat')
                    ->required()
                    ->numeric(),
                TextInput::make('contract_points')
                    ->label('Points du contrat')
                    ->required()
                    ->numeric(),
                TextInput::make('seed')->label('Graine'),
                TextInput::make('score')
                    ->label('Score')
                    ->numeric(),
                TextInput::make('score_details')->label('Détails du score'),
                TextInput::make('play_time_seconds')
                    ->label('Temps de jeu (s)')
                    ->numeric(),
                TextInput::make('replay')->label('Replay'),
                DateTimePicker::make('completed_at')->label('Terminée le'),
                Checkbox::make('is_cheat')->label('Triche'),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('score')
            ->columns([
                TextColumn::make('id')
                    ->label('ID')
                    ->searchable(),
                TextColumn::make('period_id')
                    ->label('Période')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('user.display_name')
                    ->label('Joueur')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('score')
                    ->label('Score')
                    ->numeric()
                    ->sortable(query: fn (Builder $query, string $direction) => $query->orderByRaw("score {$direction} NULLS LAST"))
                    ->searchable(),
                TextColumn::make('seed')
                    ->label('Graine')
                    ->searchable(),
                TextColumn::make('contract_score')
                    ->label('Score du contrat')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('contract_points')
                    ->label('Points du contrat')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('play_time_seconds')
                    ->label('Temps de jeu (s)')
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
                TextColumn::make('completed_at')
                    ->label('Terminée le')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('deleted_at')
                    ->label('Supprimé le')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                TrashedFilter::make(),
                Filter::make('completed_at')
                    ->default(true)
                    ->label('Parties terminées')
                    ->query(fn (Builder $query): Builder => $query->whereNotNull('completed_at')),
            ])
            ->headerActions([
                CreateAction::make(),
                AssociateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DissociateAction::make(),
                DeleteAction::make(),
                ForceDeleteAction::make(),
                RestoreAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DissociateBulkAction::make(),
                    DeleteBulkAction::make(),
                    ForceDeleteBulkAction::make(),
                    RestoreBulkAction::make(),
                ]),
            ])
            ->modifyQueryUsing(fn (Builder $query) => $query
                ->withoutGlobalScopes([
                    SoftDeletingScope::class,
                ]));
    }
}
