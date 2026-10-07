<?php

namespace App\Jobs;

use App\Models\Run;
use App\Services\SuspicionService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

// ANTI CHEAT: a run just finished, put in the queue of the suspicious runs when it looks like it (App\Services\SuspicionService)
class EvaluateRunSuspicion implements ShouldQueue
{
    use Queueable;

    public $tries = 1;

    public function __construct(public string $runId) {}

    public function handle(SuspicionService $suspicion): void
    {
        $run = Run::find($this->runId);
        if ($run) {
            $suspicion->evaluateFinishedRun($run);
        }
    }
}
