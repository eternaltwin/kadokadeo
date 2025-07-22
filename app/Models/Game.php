<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Game extends Model
{
    protected $fillable = ['name', 'description', 'category_id', 'image_path', 'stars', 'is_active', 'is_official'];

    protected $casts = [
        'stars' => 'json',
    ];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function controls()
    {
        return $this->belongsToMany(Control::class, 'control_games')
            ->withPivot('description', 'order')
            ->orderByPivot('order');
    }
}
