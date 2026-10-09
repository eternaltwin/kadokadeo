<?php

namespace App\Models;

use App\Enums\ClanBonusType;
use Illuminate\Database\Eloquent\Model;

class ClanBonus extends Model
{
    protected $fillable = ['clan_id', 'period_id', 'type', 'assigned_user_id', 'used_at'];

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

    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_user_id');
    }

    // the runs it was reserved for
    public function actions()
    {
        return $this->hasMany(ClanAction::class);
    }

    public function scopeAvailable($query)
    {
        return $query->whereNull('used_at');
    }
}
