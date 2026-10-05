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
        Schema::create('achievements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('game_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('key', 96);
            $table->string('category', 32);
            $table->string('progress_scope', 32);
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->unique(['game_id', 'key']);
            $table->index(['category', 'is_active']);
        });

        Schema::create('achievement_levels', function (Blueprint $table) {
            $table->id();
            $table->foreignId('achievement_id')->constrained()->onDelete('cascade');
            $table->unsignedInteger('level');
            $table->unsignedInteger('target');
            $table->unsignedInteger('reward');
            $table->string('title')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();

            $table->unique(['achievement_id', 'level']);
            $table->unique(['achievement_id', 'target']);
        });

        Schema::create('user_achievement_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('achievement_id')->constrained()->onDelete('cascade');
            $table->foreignId('game_id')->nullable()->constrained()->onDelete('cascade');
            $table->foreignId('period_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('scope_key', 64);
            $table->unsignedInteger('current_value')->default(0);
            $table->unsignedInteger('completed_level')->default(0);
            $table->jsonb('state')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'achievement_id', 'scope_key']);
            $table->index(['user_id', 'game_id']);
        });

        Schema::create('achievement_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('event_type', 96);
            $table->string('source_type', 96);
            $table->string('source_id', 64);
            $table->timestamp('processed_at');
            $table->timestamps();

            $table->unique(['event_type', 'source_type', 'source_id']);
            $table->index(['user_id', 'event_type']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('achievement_events');
        Schema::dropIfExists('user_achievement_progress');
        Schema::dropIfExists('achievement_levels');
        Schema::dropIfExists('achievements');
    }
};
