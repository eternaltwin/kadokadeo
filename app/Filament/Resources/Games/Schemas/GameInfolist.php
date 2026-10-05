<?php

namespace App\Filament\Resources\Games\Schemas;

use Filament\Infolists\Components\IconEntry;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Schema;

class GameInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextEntry::make('name')->label('Nom'),
                TextEntry::make('category_id')
                    ->label('Catégorie')
                    ->numeric(),
                ImageEntry::make('image_path')->label('Image'),
                IconEntry::make('is_active')
                    ->label('Actif')
                    ->boolean(),
                IconEntry::make('is_arkadeo')
                    ->label('Jeu Arkadéo')
                    ->boolean(),
                TextEntry::make('created_at')
                    ->label('Créé le')
                    ->dateTime(),
                TextEntry::make('updated_at')
                    ->label('Modifié le')
                    ->dateTime(),
            ]);
    }
}
