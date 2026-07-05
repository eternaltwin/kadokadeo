<?php

namespace App\Filament\Resources\Games\Schemas;

use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class GameForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->required(),
                Textarea::make('description')
                    ->columnSpanFull(),
                Select::make('category_id')
                    ->options(fn () => \App\Models\Category::all()->pluck('name', 'id'))
                    ->required(),
                TextInput::make('image_path'),
                Repeater::make('stars')->simple(
                    TextInput::make('value')
                        ->numeric()
                        ->required(),
                )->minItems(3)->maxItems(3),
                Toggle::make('is_active')
                    ->required(),
                Toggle::make('is_official')
                    ->required(),
            ]);
    }
}
