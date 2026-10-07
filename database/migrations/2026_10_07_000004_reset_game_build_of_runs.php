<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class() extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // the versions of the games are off (kado.game_builds.enabled): the production wipes the archive at each deploy,
        // the versions the runs remember are lost
        DB::table('runs')->whereNotNull('game_build_id')->update(['game_build_id' => null]);
        DB::table('game_builds')->delete();
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        //
    }
};
