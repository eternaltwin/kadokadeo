<?php

namespace App\Filament\Widgets;

use App\Models\Game;
use App\Models\Run;
use Carbon\Carbon;
use Filament\Forms\Components\Checkbox;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Schemas\Schema;
use Filament\Widgets\ChartWidget;
use Filament\Widgets\ChartWidget\Concerns\HasFiltersSchema;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

class RunsPlayedChart extends ChartWidget
{
    use HasFiltersSchema;

    protected ?string $heading = 'Games Runs Chart';

    protected function getData(): array
    {
        $startDate = $this->filters['startDate'];
        $endDate = $this->filters['endDate'];
        $game = $this->filters['game'] ?? null;
        $period = $this->filters['period'] ?? null;
        $complete = $this->filters['complete'] ?? null;

        $runQ = Run::query()->when($game, function ($query) use ($game) {
            return $query->where('game_id', $game);
        })->when($complete, function ($query) {
            return $query->whereNotNull('completed_at');
        });

        $data = Trend::query($runQ)
            ->between(
                start: Carbon::parse($startDate),
                end: Carbon::parse($endDate),
            );
        match ($period) {
            'day' => $data->perDay(),
            'week' => $data->perWeek(),
            'month' => $data->perMonth(),
            'year' => $data->perYear(),
            default => $data->perMonth(),
        };

        $data = $data->count();

        return [
            'datasets' => [
                [
                    'label' => 'Games played',
                    'data' => $data->map(fn (TrendValue $value) => $value->aggregate),
                ],
            ],
            'labels' => $data->map(fn (TrendValue $value) => $value->date),
        ];
    }

    public function filtersSchema(Schema $schema): Schema
    {
        return $schema->components([
            DatePicker::make('startDate')->default(now()->subDays(30)),
            DatePicker::make('endDate')->default(now()),
            Checkbox::make('completed')
                ->label('Show only completed runs')
                ->default(true),
            Select::make('period')
                ->label('Period')
                ->options([
                    'day' => 'Day',
                    'week' => 'Week',
                    'month' => 'Month',
                    'year' => 'Year',
                ])
                ->default('day'),
            Select::make('game')
                ->label('Game')
                ->options(Game::where('is_active', true)->pluck('name', 'id'))
                ->default(null),
        ]);
    }

    protected function getType(): string
    {
        return 'line';
    }
}
