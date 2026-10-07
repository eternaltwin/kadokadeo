<?php

namespace App\Models;

use App\Enums\RunFlagRule;
use App\Enums\RunFlagStatus;
use Illuminate\Database\Eloquent\Model;

// a suspicious run to review (App\Services\SuspicionService)
class RunFlag extends Model
{
    protected $fillable = ['run_id', 'user_id', 'game_id', 'rule', 'severity', 'details', 'status', 'reviewed_by', 'reviewed_at'];

    protected $attributes = [
        'status' => 'open',
    ];

    protected $casts = [
        'rule' => RunFlagRule::class,
        'status' => RunFlagStatus::class,
        'details' => 'array',
        'severity' => 'integer',
        'reviewed_at' => 'datetime',
    ];

    public function run()
    {
        return $this->belongsTo(Run::class)->withTrashed();
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function game()
    {
        return $this->belongsTo(Game::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
