<?php

namespace App\Models;

use App\Enums\ClanBonusType;
use Illuminate\Database\Eloquent\Model;

class ClanBonus extends Model
{
    protected $fillable = ['clan_id', 'period_id', 'clan_mission_id', 'type', 'used_at'];

    protected $casts = [
        'type' => ClanBonusType::class,
        'used_at' => 'datetime',
    ];

    public function clan()
    {
        return $this->belongsTo(Clan::class);
    }

    public function period()
    {
        return $this->belongsTo(Period::class);
    }

    // the mission that won the option (none for the options given at the start of the period)
    public function mission()
    {
        return $this->belongsTo(ClanMission::class, 'clan_mission_id');
    }

    public function scopeAvailable($query)
    {
        return $query->whereNull('used_at');
    }
}
