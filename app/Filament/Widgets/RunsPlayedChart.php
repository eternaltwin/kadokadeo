<?php

namespace App\Filament\Widgets;

use App\Models\Game;
use App\Models\Run;
use Carbon\Carbon;
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
        $startDate = data_get($this->filters, 'startDate');
        $endDate = data_get($this->filters, 'endDate');
        $game = data_get($this->filters, 'game');
        $period = data_get($this->filters, 'period');

        $runQ = Run::query()->when($game, function ($query) use ($game) {
            return $query->where('game_id', $game);
        });

        $dataCompleted = Trend::query($runQ->clone()->whereNotNull('completed_at'))
            ->between(
                start: Carbon::parse($startDate)->startOfDay(),
                end: Carbon::parse($endDate)->endOfDay(),
            );
        $dataNotCompleted = Trend::query($runQ->clone()->whereNull('completed_at'))
            ->between(
                start: Carbon::parse($startDate)->startOfDay(),
                end: Carbon::parse($endDate)->endOfDay(),
            );
        match ($period) {
            'day' =>
                [$dataCompleted->perDay(), $dataNotCompleted->perDay()],
            'week' =>
                [$dataCompleted->perWeek(), $dataNotCompleted->perWeek()],
            'month' =>
                [$dataCompleted->perMonth(), $dataNotCompleted->perMonth()],
            'year' =>
                [$dataCompleted->perYear(), $dataNotCompleted->perYear()],
            default =>
                [$dataCompleted->perMonth(), $dataNotCompleted->perMonth(),]
        };

        $dataCompleted = $dataCompleted->count();
        $dataNotCompleted = $dataNotCompleted->count();


        return [
            'datasets' => [
                [
                    'label' => 'Complete games played',
                    'data' => $dataCompleted->map(fn (TrendValue $value) => $value->aggregate),
                    'borderColor' => '#11AA55',
                ],
                [
                    'label' => 'Incomplete games played',
                    'data' => $dataNotCompleted->map(fn (TrendValue $value) => $value->aggregate),
                    'borderColor' => '#AA1155',
                ],
                [
                    'label' => 'Total games played',
                    'data' => $dataNotCompleted->map(fn (TrendValue $value, $key) => $value->aggregate + ($dataCompleted[$key]?->aggregate ?? 0)),
                ],
            ],
            'labels' => $dataCompleted->map(fn (TrendValue $value) => $value->date),
        ];
    }

    public function filtersSchema(Schema $schema): Schema
    {
        return $schema->components([
            DatePicker::make('startDate')->default(now()->subDays(30)),
            DatePicker::make('endDate')->default(now()),
            // Select::make('status')
            //     ->label('Run status')
            //     ->options([
            //         'complete' => 'Complete',
            //         'incomplete' => 'Incomplete',
            //     ])
            //     ->default(null),
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
