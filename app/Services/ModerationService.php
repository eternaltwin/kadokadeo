<?php

namespace App\Services;

use App\Enums\BanReason;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class ModerationService
{
    /**
     * Soft-deletes every run of the user (they can be restored from the admin) and removes the stars they earned.
     * Returns the number of deleted runs.
     */
    public function deleteScores(User $user): int
    {
        // leaderboards used to compute the league promotions of the next period
        $promotionCaches = $user->runs()
            ->whereNotNull('period_id')
            ->select('game_id', 'period_id')
            ->distinct()
            ->get()
            ->map(fn ($run) => "promotion_scores_{$run->game_id}_{$run->period_id}");

        $deleted = DB::transaction(function () use ($user) {
            $deleted = $user->runs()->delete();
            $user->gamePeriodStars()->delete();
            $user->stars()->delete();

            return $deleted;
        });

        $promotionCaches->each(fn (string $key) => cache()->forget($key));

        return $deleted;
    }

    /**
     * Deletes the scores of the user and bans them: they can no longer log in, and their sessions are refused
     * by App\Http\Middleware\EnsureUserIsNotBanned. Returns the number of deleted runs.
     */
    public function ban(User $user, BanReason $reason): int
    {
        $deleted = $this->deleteScores($user);

        $user->update([
            'banned_at' => now(),
            'ban_reason' => $reason,
        ]);

        return $deleted;
    }

    // the deleted scores are not restored
    public function unban(User $user): void
    {
        $user->update([
            'banned_at' => null,
            'ban_reason' => null,
        ]);
    }
}
