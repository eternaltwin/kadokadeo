<?php

namespace App\Filament\Resources\Users\RelationManagers;

use App\Filament\Concerns\WarnsWhenAchievementsDisabled;
use App\Models\Achievement;
use App\Models\Game;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\KeyValue;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class AchievementProgressRelationManager extends RelationManager
{
    use WarnsWhenAchievementsDisabled;

    protected static string $relationship = 'achievementProgress';

    protected static ?string $title = 'Achievements';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('achievement_id')
                    ->options(fn () => self::achievementOptions())
                    ->searchable()
                    ->required(),
                Select::make('game_id')
                    ->options(fn () => Game::query()->orderBy('name')->pluck('name', 'id'))
                    ->searchable()
                    ->placeholder('Global'),
                TextInput::make('period_id')
                    ->numeric(),
                TextInput::make('scope_key')
                    ->required()
                    ->maxLength(64),
                TextInput::make('current_value')
                    ->required()
                    ->numeric()
                    ->minValue(0),
                TextInput::make('completed_level')
                    ->required()
                    ->numeric()
                    ->minValue(0),
                DateTimePicker::make('completed_at'),
                KeyValue::make('state')
                    ->columnSpanFull(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('id')
            ->description(fn () => static::achievementsDisabledNotice())
            ->columns([
                TextColumn::make('id')
                    ->label('ID')
                    ->sortable(),
                TextColumn::make('achievement.key')
                    ->label('Achievement')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('game.name')
                    ->placeholder('Global')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('achievement.category')
                    ->label('Category')
                    ->formatStateUsing(fn (mixed $state): string => self::formatEnumState($state))
                    ->sortable(),
                TextColumn::make('achievement.progress_scope')
                    ->label('Scope')
                    ->formatStateUsing(fn (mixed $state): string => self::formatEnumState($state))
                    ->sortable(),
                TextColumn::make('scope_key')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('current_value')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('completed_level')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('period_id')
                    ->numeric()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('state')
                    ->formatStateUsing(fn (mixed $state): string => $state ? json_encode($state) ?: '-' : '-')
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('completed_at')
                    ->dateTime()
                    ->sortable(),
                TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Filter::make('completed')
                    ->query(fn (Builder $query): Builder => $query->where('completed_level', '>', 0)),
                SelectFilter::make('achievement_id')
                    ->label('Achievement')
                    ->options(fn () => self::achievementOptions())
                    ->searchable(),
                SelectFilter::make('game_id')
                    ->label('Game')
                    ->options(fn () => Game::query()->orderBy('name')->pluck('name', 'id'))
                    ->searchable(),
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ])
            ->modifyQueryUsing(fn (Builder $query): Builder => $query->with(['achievement.game', 'game']));
    }

    private static function achievementOptions()
    {
        return Achievement::query()
            ->with('game')
            ->orderBy('key')
            ->get()
            ->mapWithKeys(fn (Achievement $achievement): array => [
                $achievement->id => ($achievement->game?->name ?? 'Global').' / '.$achievement->key,
            ]);
    }

    private static function formatEnumState(mixed $state): string
    {
        if ($state instanceof \BackedEnum) {
            return self::formatOption((string) $state->value);
        }

        return self::formatOption($state === null ? null : (string) $state);
    }

    private static function formatOption(?string $value): string
    {
        if ($value === null || $value === '') {
            return '-';
        }

        return ucfirst(str_replace('_', ' ', $value));
    }
}
