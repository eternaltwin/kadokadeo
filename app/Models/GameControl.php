<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class GameControl extends Model
{
    public $timestamps = false;

    protected $fillable = ['description', 'keys', 'order'];

    protected $casts = [
        'keys' => 'array',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }
}
