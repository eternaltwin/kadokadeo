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
        // what the analyzer of the game said of the moves of the replay (resources/js/replay-verifier/analyzers)
        Schema::table('replay_verifications', function (Blueprint $table) {
            $table->json('analysis')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('replay_verifications', function (Blueprint $table) {
            $table->dropColumn('analysis');
        });
    }
};
