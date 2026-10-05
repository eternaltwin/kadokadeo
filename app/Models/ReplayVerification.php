<?php

namespace App\Models;

use App\Enums\RunVerification;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\MassPrunable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

// one verification of the replay of a run (App\Jobs\VerifyRunReplay)
class ReplayVerification extends Model
{
    use MassPrunable;

    // the verified runs are kept 30 days (the stats of the admin page), the others (cheats, failures) for good
    public const KEEP_VERIFIED_DAYS = 30;

    public const UPDATED_AT = null;

    protected $fillable = ['run_id', 'game_id', 'status', 'score', 'replay_score', 'frames', 'error', 'duration_ms'];

    protected $casts = [
        'status' => RunVerification::class,
    ];

    public function run(): BelongsTo
    {
        return $this->belongsTo(Run::class)->withTrashed();
    }

    public function game(): BelongsTo
    {
        return $this->belongsTo(Game::class);
    }

    public function prunable(): Builder
    {
        return static::where('status', RunVerification::VERIFIED)
            ->where('created_at', '<', now()->subDays(self::KEEP_VERIFIED_DAYS));
    }
}
