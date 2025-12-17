<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DailyGame extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'day',
        'game_id',
        'seed',
        'contract_score',
        'contract_points',
    ];

    protected $casts = [
        'day' => 'date',
        'contract_score' => 'integer',
        'contract_points' => 'integer',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function runs()
    {
        return $this->hasMany(Run::class);
    }
}
