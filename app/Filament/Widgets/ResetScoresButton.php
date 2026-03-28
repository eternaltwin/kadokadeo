<?php

namespace App\Filament\Widgets;

use Filament\Notifications\Notification;
use Filament\Widgets\Widget;
use Illuminate\Support\Facades\Artisan;
use Throwable;

class ResetScoresButton extends Widget
{
    protected string $view = 'filament.widgets.reset-scores-button';

    protected int|string|array $columnSpan = 'full';

    protected static ?int $sort = 3;

    public function resetScores(): void
    {
        try {
            Artisan::call('kado:reset-scores');

            Notification::make()
                ->title('Scores reset successfully.')
                ->success()
                ->send();
        } catch (Throwable $exception) {
            report($exception);

            Notification::make()
                ->title('Unable to reset scores.')
                ->body('Check logs for details and try again.')
                ->danger()
                ->send();
        }
    }
}
