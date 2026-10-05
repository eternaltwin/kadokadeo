<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AchievementLevel extends Model
{
    use HasFactory;

    protected $fillable = ['achievement_id', 'level', 'target', 'reward', 'title', 'description'];

    public function achievement()
    {
        return $this->belongsTo(Achievement::class);
    }

    public function getIconAttribute()
    {
        $achievement = $this->achievement;
        if (!$achievement?->game) {
            return null;
        }

        return url('/gfx/achievements/levels/'.$achievement->game->game_key.'/'.$achievement->key.'-'.$this->level.'.png');
    }
}
