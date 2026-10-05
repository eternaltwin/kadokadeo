<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class() extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // one row per verification of a replay (App\Jobs\VerifyRunReplay): the history and the stats of the verifier.
        // runs.verification keeps the state of the run
        Schema::create('replay_verifications', function (Blueprint $table) {
            $table->id();
            $table->foreignUlid('run_id')->constrained()->cascadeOnDelete();
            $table->foreignId('game_id')->constrained()->cascadeOnDelete();
            $table->string('status', 16);
            // the score sent by the game, and the one the replay ends with
            $table->bigInteger('score');
            $table->bigInteger('replay_score')->nullable();
            $table->integer('frames')->nullable();
            $table->text('error')->nullable();
            $table->integer('duration_ms')->nullable();
            $table->timestamp('created_at')->index();
            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('replay_verifications');
    }
};
