<?php

namespace App\Filament\Resources\Games\Pages;

use App\Filament\Resources\Games\GameResource;
use App\Models\Game;
use App\Models\Run;
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
            Action::make('deleteReplays')
                ->label('Delete replays')
                ->color('danger')
                ->requiresConfirmation()
                ->modalHeading('Delete game replays')
                ->modalDescription('This will delete all replays for this game. This action cannot be undone.')
                ->action(function (): void {
                    try {
                        Run::where('game_id', $this->record->id)->update(['replay' => null]);

                        Notification::make()
                            ->title('Replays deleted successfully.')
                            ->success()
                            ->send();
                    } catch (Throwable $exception) {
                        report($exception);

                        Notification::make()
                            ->title('Unable to delete replays.')
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
