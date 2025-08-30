<?php

namespace App\Models;

use App\Casts\BinaryCast;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Run extends Model
{
    use SoftDeletes;
    use HasUlids;

    protected $fillable = ['period_id', 'game_id', 'user_id', 'score', 'play_time_seconds', 'replay', 'completed_at', 'contract_score', 'contract_points', 'seed', 'score_details'];

    protected $casts = [
        'replay' => BinaryCast::class,
        'completed_at' => 'datetime',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

}
