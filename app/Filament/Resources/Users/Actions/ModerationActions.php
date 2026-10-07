<?php

namespace App\Filament\Resources\Users\Actions;

use App\Enums\BanReason;
use App\Models\User;
use App\Services\ModerationService;
use Closure;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Support\Icons\Heroicon;

class ModerationActions
{
    public static function all(): array
    {
        return [
            self::deleteScores(),
            self::ban(),
            self::unban(),
        ];
    }

    public static function deleteScores(): Action
    {
        return Action::make('deleteScores')
            ->label('Supprimer les scores')
            ->icon(Heroicon::OutlinedTrash)
            ->color('danger')
            ->requiresConfirmation()
            ->modalHeading(fn (User $record) => "Supprimer les scores de {$record->display_name}")
            ->modalDescription('Toutes les parties du joueur seront supprimées (restaurables depuis la liste de ses parties) et ses étoiles retirées.')
            ->modalSubmitActionLabel('Supprimer')
            ->action(function (User $record, ModerationService $moderation): void {
                $deleted = $moderation->deleteScores($record);

                Notification::make()
                    ->title('Scores supprimés.')
                    ->body("{$deleted} partie(s) supprimée(s).")
                    ->success()
                    ->send();
            });
    }

    // $user: the player of a record of the table (by default the record)
    public static function ban(?Closure $user = null): Action
    {
        $user ??= fn (User $record) => $record;

        return Action::make('ban')
            ->label('Bannir')
            ->icon(Heroicon::OutlinedNoSymbol)
            ->color('danger')
            ->visible(fn ($record) => ($player = $user($record)) !== null && !$player->isBanned() && !$player->is(auth()->user()))
            ->requiresConfirmation()
            ->modalHeading(fn ($record) => "Bannir {$user($record)->display_name}")
            ->modalDescription('Le joueur sera déconnecté et ne pourra plus se connecter. Toutes ses parties seront supprimées et ses étoiles retirées.')
            ->modalSubmitActionLabel('Bannir')
            ->schema([
                Select::make('reason')
                    ->label('Raison')
                    ->options(BanReason::class)
                    ->required(),
            ])
            ->action(function ($record, array $data, ModerationService $moderation) use ($user): void {
                $player = $user($record);
                $reason = $data['reason'] instanceof BanReason ? $data['reason'] : BanReason::from($data['reason']);
                $deleted = $moderation->ban($player, $reason);

                Notification::make()
                    ->title("{$player->display_name} a été banni.")
                    ->body("{$deleted} partie(s) supprimée(s).")
                    ->success()
                    ->send();
            });
    }

    public static function unban(): Action
    {
        return Action::make('unban')
            ->label('Débannir')
            ->icon(Heroicon::OutlinedCheckCircle)
            ->color('gray')
            ->visible(fn (User $record) => $record->isBanned())
            ->requiresConfirmation()
            ->modalHeading(fn (User $record) => "Débannir {$record->display_name}")
            ->modalDescription('Le joueur pourra de nouveau se connecter. Ses scores supprimés ne sont pas restaurés.')
            ->modalSubmitActionLabel('Débannir')
            ->action(function (User $record, ModerationService $moderation): void {
                $moderation->unban($record);

                Notification::make()
                    ->title("{$record->display_name} a été débanni.")
                    ->success()
                    ->send();
            });
    }
}
