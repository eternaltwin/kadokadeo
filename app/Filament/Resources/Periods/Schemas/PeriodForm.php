<?php

namespace App\Filament\Resources\Periods\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Schemas\Schema;

class PeriodForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                DateTimePicker::make('start_at'),
                DateTimePicker::make('end_at'),
            ]);
    }
}
