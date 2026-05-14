<?php

namespace App\Filament\Resources\Leagues\Schemas;

use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class LeagueForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('level')
                    ->required()
                    ->numeric(),
                TextInput::make('name')
                    ->required(),
                TextInput::make('promotion_max_slots')
                    ->numeric(),
                TextInput::make('promotion_ratio_divisor')
                    ->numeric(),
                TextInput::make('promotion_min_stars')
                    ->numeric(),
                TextInput::make('promotion_reward')
                    ->numeric(),
            ]);
    }
}
