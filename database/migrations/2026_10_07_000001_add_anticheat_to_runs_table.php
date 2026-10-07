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
        Schema::table('runs', function (Blueprint $table) {
            // what the game detected during the run (App\Enums\AntiCheatBit)
            $table->unsignedInteger('anticheat_flags')->default(0);
            // number of frames of its replay ("LEN" trailer, App\Support\ReplayHeader)
            $table->unsignedInteger('replay_frames')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('runs', function (Blueprint $table) {
            $table->dropColumn(['anticheat_flags', 'replay_frames']);
        });
    }
};
