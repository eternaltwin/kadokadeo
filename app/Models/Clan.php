<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Clan extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'leader_id', 'is_recruiting'];

    protected $casts = [
        'is_recruiting' => 'boolean',
    ];

    public function leader()
    {
        return $this->belongsTo(User::class, 'leader_id');
    }

    public function members()
    {
        return $this->hasMany(ClanMember::class);
    }

    public function users()
    {
        return $this->belongsToMany(User::class, 'clan_members')->withTimestamps();
    }

    public function applications()
    {
        return $this->hasMany(ClanApplication::class);
    }

    public function periodScores()
    {
        return $this->hasMany(ClanPeriodScore::class);
    }

    public function memberStats()
    {
        return $this->hasMany(ClanMemberStat::class);
    }

    public function missions()
    {
        return $this->hasMany(ClanMission::class);
    }

    public function bonuses()
    {
        return $this->hasMany(ClanBonus::class);
    }

    public function attacksLaunched()
    {
        return $this->hasMany(ClanAttack::class, 'attacker_clan_id');
    }

    public function attacksReceived()
    {
        return $this->hasMany(ClanAttack::class, 'defender_clan_id');
    }
}
