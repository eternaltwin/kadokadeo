<?php

namespace Tests\Feature;

use App\Models\DailyGame;
use App\Models\Game;
use App\Models\Run;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DailyReplayVisibilityTest extends TestCase
{
    use RefreshDatabase;

    private function dailyRun(string $day): Run
    {
        $game = Game::factory()->create();
        $daily = DailyGame::create(['day' => $day, 'game_id' => $game->id, 'seed' => 'daily-seed', 'contract_score' => 0, 'contract_points' => 0]);

        return Run::factory()->for($game)->create(['daily_game_id' => $daily->id, 'seed' => 'daily-seed', 'replay' => 'replay-data']);
    }

    public function test_the_replay_of_todays_daily_game_is_only_visible_to_its_player_and_the_admins(): void
    {
        $run = $this->dailyRun(today()->toDateString());

        $this->assertFalse(User::factory()->create()->can('view', $run));
        $this->assertTrue($run->user->can('view', $run));
        $this->assertTrue(User::factory()->create(['is_admin' => true])->can('view', $run));
    }

    public function test_the_replay_of_a_past_daily_game_is_visible_to_everyone(): void
    {
        $run = $this->dailyRun(today()->subDay()->toDateString());

        $this->assertTrue(User::factory()->create()->can('view', $run));
    }

    public function test_the_lists_of_runs_never_give_the_seed_nor_the_replay(): void
    {
        $run = $this->dailyRun(today()->toDateString());
        Sanctum::actingAs(User::factory()->create());

        $response = $this->getJson("/api/users/{$run->user->etwin_id}/history")->assertOk();

        $this->assertArrayNotHasKey('seed', $response->json('data.0'));
        $this->assertArrayNotHasKey('replay', $response->json('data.0'));
        // no link to a replay that would be refused
        $this->assertFalse($response->json('data.0.has_replay'));
    }
}
