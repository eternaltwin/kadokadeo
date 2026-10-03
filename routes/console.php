<?php

// use App\Console\Commands\CleanOldRuns;

use App\Console\Commands\KeepGameBuilds;
use App\Console\Commands\PrepareDailyGame;
use App\Console\Commands\PrepareNewPeriod;
use App\Console\Commands\ResetDailyGames;
use Illuminate\Support\Facades\Schedule;

Schedule::command(ResetDailyGames::class)->daily();
Schedule::command(PrepareDailyGame::class)->daily();
// Schedule::command(CleanOldRuns::class)->twiceDailyAt(6, 18);
Schedule::command(PrepareNewPeriod::class)->weeklyOn(1);
// versions of the games still used by replays (the next build removes the others)
Schedule::command(KeepGameBuilds::class)->daily();
