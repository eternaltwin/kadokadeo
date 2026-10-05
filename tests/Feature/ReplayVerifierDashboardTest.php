<?php

namespace Tests\Feature;

use App\Enums\RunVerification;
use App\Filament\Pages\ReplayVerifierDashboard;
use App\Filament\Widgets\ReplayVerificationStats;
use App\Models\ReplayVerification;
use App\Models\Run;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class ReplayVerifierDashboardTest extends TestCase
{
    use RefreshDatabase;

    private function verification(Run $run, RunVerification $status, array $attributes = []): ReplayVerification
    {
        return ReplayVerification::create(['run_id' => $run->id, 'game_id' => $run->game_id, 'status' => $status, 'score' => $run->score, 'duration_ms' => 1900, ...$attributes]);
    }

    public function test_the_page_lists_the_verifications_with_their_errors_and_counts_them_by_game(): void
    {
        $run = Run::factory()->create(['score' => 500]);
        $verified = $this->verification($run, RunVerification::VERIFIED, ['replay_score' => 500]);
        $this->verification($run, RunVerification::MISMATCH, ['replay_score' => 20]);
        $this->verification($run, RunVerification::FAILED, ['error' => 'libnss3.so: cannot open shared object file']);
        $this->actingAs(User::factory()->create(['is_admin' => true]));

        Livewire::test(ReplayVerifierDashboard::class)
            ->assertSee('libnss3.so')
            ->assertSee('Par jeu')
            ->assertSee($run->game->name)
            ->assertSee('Score différent')
            // the replay in a modal
            ->mountTableAction('watchReplay', $verified)
            ->assertMountedActionModalSeeHtml(route('filament.admin.runs.replay', $run->id));

        $this->assertEquals(
            [['game' => $run->game->name, 'counts' => ['verified' => 1, 'mismatch' => 1, 'failed' => 1]]],
            Livewire::test(ReplayVerifierDashboard::class)->instance()->perGame(),
        );
    }

    public function test_the_stats_count_the_last_7_days(): void
    {
        $run = Run::factory()->create();
        $this->verification($run, RunVerification::VERIFIED);
        $this->verification($run, RunVerification::MISMATCH);
        $this->verification($run, RunVerification::NO_REPLAY);
        $this->verification($run, RunVerification::FAILED)->forceFill(['created_at' => now()->subDays(8)])->save();
        $this->actingAs(User::factory()->create(['is_admin' => true]));

        Livewire::test(ReplayVerificationStats::class)
            ->assertSeeInOrder(['Replays vérifiés', '1', 'Triches détectées', '2', '1 score(s) différent(s), 1 sans replay valide', 'Échecs de vérification', '0', 'Durée moyenne', '1,9 s']);
    }
}
