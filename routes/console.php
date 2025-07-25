<?php

use App\Console\Commands\PrepareNewPeriod;
use App\Console\Commands\ResetDailyGames;
use Illuminate\Support\Facades\Schedule;

Schedule::command(ResetDailyGames::class)->daily();
Schedule::command(PrepareNewPeriod::class)->weeklyOn(1);
