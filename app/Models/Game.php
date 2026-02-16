<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class Game extends Model
{
    protected $fillable = ['name', 'description', 'category_id', 'image_path', 'stars', 'is_active', 'is_official'];

    protected $casts = [
        'stars' => 'json',
    ];

    protected $with = ['category'];

    public function getGamedataAttribute()
    {
        $fileName = $this->game_key . '.js';
        $filePath = public_path('gamesdata/' . $fileName);
        if (!file_exists($filePath)) {
            return null;
        }

        return Cache::remember(sprintf('gamedata_%s', $this->id), now()->addDay(), function () use ($fileName, $filePath) {
            return [
                'file' => '/gamesdata/' . $fileName,
                'size' => filesize($filePath),
            ];
        });
    }

    public function getPascalNameAttribute(): string
    {
        return Str::of('Game'.$this->name)->pascal()->toString();
    }

    public function getGameKeyAttribute(): string
    {
        return Str::of($this->name)->lower()->replaceMatches('/[^a-z0-9]/', '')->toString();
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function runs()
    {
        return $this->hasMany(Run::class);
    }

    public function dailyGames()
    {
        return $this->hasMany(DailyGame::class);
    }

    public function controls()
    {
        return $this->hasMany(GameControl::class)
            ->orderBy('order');
    }
}
