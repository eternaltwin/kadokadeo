<?php

use App\Models\Run;
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
        Run::whereNotNull('data')->chunkById(100, function ($runs) {
            foreach ($runs as $run) {
                $data = json_decode($run->data, true);
                $run->score_details = $data ?? null;
                $run->save();
            }
        });
        Schema::table('runs', function (Blueprint $table) {
            $table->dropColumn('data');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('runs', function (Blueprint $table) {
            $table->json('data')->nullable();
        });
    }
};
