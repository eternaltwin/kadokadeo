<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Control extends Model
{
    protected $fillable = ['name', 'key'];
    public $timestamps = false;

    public function games()
    {
        return $this->belongsToMany(Game::class, 'control_games');
    }
}
