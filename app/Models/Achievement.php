<?php

namespace App\Models;

use App\Enums\AchievementCategory;
use App\Enums\AchievementProgressScope;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Achievement extends Model
{
    use HasFactory;

    protected $fillable = ['game_id', 'key', 'category', 'progress_scope', 'is_active'];

    protected $casts = [
        'category' => AchievementCategory::class,
        'progress_scope' => AchievementProgressScope::class,
        'is_active' => 'boolean',
    ];

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function levels()
    {
        return $this->hasMany(AchievementLevel::class)->orderBy('level');
    }

    public function progress()
    {
        return $this->hasMany(UserAchievementProgress::class);
    }
}
