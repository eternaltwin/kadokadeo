<?php

namespace App\Filament\Widgets;

use App\Models\User;
use Carbon\Carbon;
use Filament\Forms\Components\DatePicker;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;
use Illuminate\Database\Eloquent\Builder;

class TopPlayersWidget extends BaseWidget
{
    protected static ?string $heading = 'Top joueurs';

    protected int|string|array $columnSpan = 'full';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                User::query()
                    ->join('runs', 'users.id', '=', 'runs.user_id')
                    ->whereNotNull('runs.completed_at')
                    ->groupBy('users.id')
                    ->selectRaw('users.*, COUNT(runs.id) as completed_count')
                    ->orderByDesc('completed_count')
            )
            ->columns([
                TextColumn::make('display_name')
                    ->label('Joueur')
                    ->searchable(),
                TextColumn::make('completed_count')
                    ->label('Parties terminées')
                    ->numeric()
                    ->sortable(),
            ])
            ->filters([
                Filter::make('period')
                    ->label('Période')
                    ->form([
                        DatePicker::make('start_date')
                            ->label('Du')
                            ->default(now()->subMonth()),
                        DatePicker::make('end_date')
                            ->label('Au')
                            ->default(now()),
                    ])
                    ->query(fn (Builder $query, array $data) => $query
                        ->when(
                            $data['start_date'],
                            fn ($q) => $q->where('runs.completed_at', '>=', Carbon::parse($data['start_date'])->startOfDay())
                        )
                        ->when(
                            $data['end_date'],
                            fn ($q) => $q->where('runs.completed_at', '<=', Carbon::parse($data['end_date'])->endOfDay())
                        )
                    )
                    ->indicateUsing(function (array $data): array {
                        $indicators = [];
                        if ($data['start_date'] ?? null) {
                            $indicators[] = 'Du '.Carbon::parse($data['start_date'])->format('d/m/Y');
                        }
                        if ($data['end_date'] ?? null) {
                            $indicators[] = 'Au '.Carbon::parse($data['end_date'])->format('d/m/Y');
                        }

                        return $indicators;
                    }),
            ])
            ->defaultSort('completed_count', 'desc');
    }
}
