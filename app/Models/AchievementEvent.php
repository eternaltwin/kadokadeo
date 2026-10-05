<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AchievementEvent extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'event_type', 'source_type', 'source_id', 'processed_at'];

    protected $casts = [
        'processed_at' => 'datetime',
    ];
}
