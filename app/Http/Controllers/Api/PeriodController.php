<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PeriodResource;

class PeriodController extends Controller
{
    public function current()
    {
        $currentPeriod = \App\Models\Period::current()->first();

        return PeriodResource::make($currentPeriod);
    }
}
