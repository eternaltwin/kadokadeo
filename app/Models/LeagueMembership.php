<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LeagueMembership extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'period_id', 'game_id', 'league_id'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function league()
    {
        return $this->belongsTo(League::class);
    }
}
