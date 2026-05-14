<?php

namespace App\Filament\Resources\Games;

use App\Filament\Resources\Games\Pages\CreateGame;
use App\Filament\Resources\Games\Pages\EditGame;
use App\Filament\Resources\Games\Pages\ListGames;
use App\Filament\Resources\Games\Pages\ViewGame;
use App\Filament\Resources\Games\RelationManagers\ControlsRelationManager;
use App\Filament\Resources\Games\RelationManagers\RunsRelationManager;
use App\Filament\Resources\Games\Schemas\GameForm;
use App\Filament\Resources\Games\Schemas\GameInfolist;
use App\Filament\Resources\Games\Tables\GamesTable;
use App\Livewire\GameLeaguesOverview;
use App\Models\Game;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class GameResource extends Resource
{
    protected static ?string $model = Game::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedRectangleStack;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return GameForm::configure($schema);
    }

    public static function infolist(Schema $schema): Schema
    {
        return GameInfolist::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return GamesTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            RunsRelationManager::class,
            ControlsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListGames::route('/'),
            'create' => CreateGame::route('/create'),
            'view' => ViewGame::route('/{record}'),
            'edit' => EditGame::route('/{record}/edit'),
        ];
    }

    public static function getWidgets(): array
    {
        return [
            GameLeaguesOverview::class,
        ];
    }
}
