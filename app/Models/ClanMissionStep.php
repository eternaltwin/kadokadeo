<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ClanMissionStep extends Model
{
    protected $fillable = [
        'clan_mission_id',
        'game_id',
        'target_score',
        'completed_by_user_id',
        'run_id',
        'score',
        'skipped',
        'completed_at',
    ];

    protected $casts = [
        'target_score' => 'integer',
        'score' => 'integer',
        'skipped' => 'boolean',
        'completed_at' => 'datetime',
    ];

    public function mission()
    {
        return $this->belongsTo(ClanMission::class, 'clan_mission_id');
    }

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function completedBy()
    {
        return $this->belongsTo(User::class, 'completed_by_user_id');
    }

    public function isDone(): bool
    {
        return $this->completed_at !== null || $this->skipped;
    }
}
