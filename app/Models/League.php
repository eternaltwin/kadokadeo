<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class League extends Model
{
    use HasFactory;

    protected $fillable = [
        'level',
        'name',
        'promotion_max_slots',
        'promotion_ratio_divisor',
        'promotion_min_stars',
        'promotion_reward',
    ];

    protected $casts = [
        'level' => 'integer',
        'promotion_max_slots' => 'integer',
        'promotion_ratio_divisor' => 'integer',
        'promotion_min_stars' => 'integer',
        'promotion_reward' => 'integer',
    ];

    public function scopeOrdered($query)
    {
        return $query->orderBy('level');
    }

    public function runs()
    {
        return $this->hasMany(Run::class);
    }

    public function memberships()
    {
        return $this->hasMany(LeagueMembership::class);
    }

    public function promotionsFrom()
    {
        return $this->hasMany(LeaguePromotion::class, 'from_league_id');
    }

    public function promotionsTo()
    {
        return $this->hasMany(LeaguePromotion::class, 'to_league_id');
    }
}
