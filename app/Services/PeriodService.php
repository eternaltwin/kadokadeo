<?php

namespace App\Services;

use App\Models\Period;

class PeriodService
{
    public function getDayCount(): int
    {
        $p = Period::current()->first();

        if (! $p) {
            return 0;
        }

        return $p->start_at->diffInDays(now());
    }
}
