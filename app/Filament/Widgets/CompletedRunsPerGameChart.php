<?php

namespace App\Filament\Widgets;

use App\Models\Game;
use App\Models\Run;
use Carbon\Carbon;
use Filament\Forms\Components\DatePicker;
use Filament\Schemas\Schema;
use Filament\Widgets\ChartWidget;
use Filament\Widgets\ChartWidget\Concerns\HasFiltersSchema;
use Flowframe\Trend\Trend;
use Flowframe\Trend\TrendValue;

class CompletedRunsPerGameChart extends ChartWidget
{
    use HasFiltersSchema;

    protected ?string $heading = 'Completed runs per game';

    protected function getData(): array
    {
        $startDate = data_get($this->filters, 'startDate') ?? now()->subDays(30)->toDateString();
        $endDate = data_get($this->filters, 'endDate') ?? now()->toDateString();

        $games = Game::where('is_active', true)->get();

        $datasets = [];
        $labels = null;
        $total = $games->count();

        foreach ($games as $index => $game) {
            $trend = Trend::query(Run::whereNotNull('completed_at')->where('game_id', $game->id))
                ->between(
                    start: Carbon::parse($startDate)->startOfDay(),
                    end: Carbon::parse($endDate)->endOfDay(),
                )
                ->perDay()
                ->count();

            if ($labels === null) {
                $labels = $trend->map(fn (TrendValue $value) => $value->date);
            }

            $hue = $total > 1 ? (int) round($index * 360 / $total) : 200;
            $color = "hsl({$hue}, 70%, 50%)";

            $datasets[] = [
                'label' => $game->name,
                'data' => $trend->map(fn (TrendValue $value) => $value->aggregate),
                'borderColor' => $color,
                'backgroundColor' => $color,
            ];
        }

        return [
            'datasets' => $datasets,
            'labels' => $labels ?? [],
        ];
    }

    public function filtersSchema(Schema $schema): Schema
    {
        return $schema->components([
            DatePicker::make('startDate')->default(now()->subDays(30)),
            DatePicker::make('endDate')->default(now()),
        ]);
    }

    protected function getType(): string
    {
        return 'line';
    }
}
