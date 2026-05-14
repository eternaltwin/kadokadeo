<?php

use App\Models\Run;
use Illuminate\Database\Migrations\Migration;

return new class() extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Run::query()
            ->whereNull('league_id')
            ->update(['league_id' => 1]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void {}
};
