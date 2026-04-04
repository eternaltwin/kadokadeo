<?php

namespace App\Filament\Resources\Games\Pages;

use App\Filament\Resources\Games\GameResource;
use Filament\Actions\Action;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Support\Facades\Artisan;
use Throwable;

class EditGame extends EditRecord
{
    protected static string $resource = GameResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('resetScores')
                ->label('Reset scores')
                ->color('danger')
                ->requiresConfirmation()
                ->modalHeading('Reset game scores')
                ->modalDescription('This will delete all runs for this game. This action cannot be undone.')
                ->action(function (): void {
                    try {
                        Artisan::call('kado:reset-scores', [
                            'gameId' => $this->record->id,
                        ]);

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
                }),
            ViewAction::make(),
            DeleteAction::make(),
        ];
    }
}
