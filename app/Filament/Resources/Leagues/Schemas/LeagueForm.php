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
                    ->label('Niveau')
                    ->required()
                    ->numeric(),
                TextInput::make('name')
                    ->label('Nom')
                    ->required(),
                TextInput::make('promotion_max_slots')
                    ->label('Places de promotion max')
                    ->numeric(),
                TextInput::make('promotion_ratio_divisor')
                    ->label('Diviseur du ratio de promotion')
                    ->numeric(),
                TextInput::make('promotion_min_stars')
                    ->label('Étoiles min. pour la promotion')
                    ->numeric(),
                TextInput::make('promotion_reward')
                    ->label('Récompense de promotion')
                    ->numeric(),
            ]);
    }
}
