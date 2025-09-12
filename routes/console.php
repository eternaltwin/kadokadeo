<?php

// use App\Console\Commands\CleanOldRuns;

use App\Console\Commands\PrepareDailyGame;
use App\Console\Commands\PrepareNewPeriod;
use App\Console\Commands\ResetDailyGames;
use Illuminate\Support\Facades\Schedule;

Schedule::command(ResetDailyGames::class)->daily();
Schedule::command(PrepareDailyGame::class)->daily();
// Schedule::command(CleanOldRuns::class)->twiceDailyAt(6, 18);
Schedule::command(PrepareNewPeriod::class)->weeklyOn(1);
