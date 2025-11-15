<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GamePeriodStar extends Model
{
    protected $fillable = [
        'game_id',
        'period_id',
        'user_id',
        'star',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
