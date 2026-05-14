<?php

namespace App\Models;

use App\Casts\BinaryCast;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Run extends Model
{
    use HasFactory;
    use HasUlids;
    use SoftDeletes;

    protected $fillable = ['period_id', 'game_id', 'user_id', 'league_id', 'score', 'play_time_seconds', 'replay', 'completed_at', 'contract_score', 'contract_points', 'seed', 'score_details', 'daily_game_id'];

    protected $casts = [
        'replay' => BinaryCast::class,
        'completed_at' => 'datetime',
        'score_details' => 'array',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    public function league()
    {
        return $this->belongsTo(League::class);
    }

    public function getHasReplayAttribute()
    {
        return !is_null($this->replay);
    }
}
