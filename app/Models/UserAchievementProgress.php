<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserAchievementProgress extends Model
{
    use HasFactory;

    protected $table = 'user_achievement_progress';

    protected $fillable = [
        'user_id',
        'achievement_id',
        'game_id',
        'period_id',
        'scope_key',
        'current_value',
        'completed_level',
        'state',
        'completed_at',
    ];

    protected $casts = [
        'state' => 'array',
        'completed_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function achievement()
    {
        return $this->belongsTo(Achievement::class);
    }

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }
}
