<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Period extends Model
{
    public const DAYS_PER_PERIOD = 13;

    public $timestamps = false;
    protected $fillable = ['start_at', 'end_at'];

    protected $casts = [
        'start_at' => 'datetime',
        'end_at' => 'datetime',
    ];

    public function scopeCurrent($query)
    {
        return $query->where('start_at', '<', now())->where('end_at', '>', now())->orderBy('end_at');
    }
}
