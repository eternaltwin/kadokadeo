<?php

namespace App\Filament\Resources\Games\Pages;

use App\Filament\Resources\Games\GameResource;
use App\Models\Run;
use Filament\Actions\Action;
use Filament\Actions\DeleteAction;
use Filament\Actions\ViewAction;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
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
            Action::make('resetReplays')
                ->label('Reset replays')
                ->color('danger')
                ->requiresConfirmation()
                ->modalHeading('Reset game replays')
                ->modalDescription('This will delete all replays for this game. This action cannot be undone.')
                ->action(function (): void {
                    try {
                        Run::where('game_id', $this->record->id)->update(['replay' => null]);

                        Notification::make()
                            ->title('Replays reset successfully.')
                            ->success()
                            ->send();
                    } catch (Throwable $exception) {
                        report($exception);

                        Notification::make()
                            ->title('Unable to reset replays.')
                            ->body('Check logs for details and try again.')
                            ->danger()
                            ->send();
                    }
                }),
            Action::make('clearCache')
                ->label('Clear gamedata cache')
                ->color('warning')
                ->action(function (): void {
                    try {
                        Cache::forget(sprintf('gamedata_%s', $this->record->id));

                        Notification::make()
                            ->title('Gamedata cache cleared successfully.')
                            ->success()
                            ->send();
                    } catch (Throwable $exception) {
                        report($exception);

                        Notification::make()
                            ->title('Unable to clear gamedata cache.')
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
