<?php

namespace App\Filament\Resources\Runs;

use App\Filament\Resources\Runs\Pages\EditRun;
use App\Filament\Resources\Runs\Pages\ListRuns;
use App\Models\Run;
use Filament\Forms\Components\Checkbox;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;

class RunResource extends Resource
{
    protected static ?string $model = Run::class;

    protected static bool $shouldRegisterNavigation = false;

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('period_id')
                ->numeric(),
            TextInput::make('user_id')
                ->required()
                ->numeric(),
            TextInput::make('contract_score')
                ->numeric(),
            TextInput::make('contract_points')
                ->numeric(),
            TextInput::make('seed'),
            TextInput::make('score')
                ->numeric(),
            TextInput::make('score_details'),
            TextInput::make('play_time_seconds')
                ->numeric(),
            TextInput::make('replay'),
            DateTimePicker::make('completed_at'),
            Checkbox::make('is_cheat'),
        ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListRuns::route('/'),
            'edit' => EditRun::route('/{record}/edit'),
        ];
    }
}
