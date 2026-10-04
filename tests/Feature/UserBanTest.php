<?php

namespace Tests\Feature;

use App\Enums\BanReason;
use App\Filament\Resources\Users\Pages\EditUser;
use App\Filament\Resources\Users\Pages\ListUsers;
use App\Models\Game;
use App\Models\GamePeriodStar;
use App\Models\Period;
use App\Models\Run;
use App\Models\User;
use App\Services\ModerationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Livewire\Livewire;
use Tests\TestCase;

class UserBanTest extends TestCase
{
    use RefreshDatabase;

    private function createPlayerWithScores(): User
    {
        $user = User::factory()->create();
        $game = Game::factory()->create();
        $period = Period::factory()->create();
        Run::factory()->count(3)->for($game)->for($user)->create(['period_id' => $period->id]);
        GamePeriodStar::create(['game_id' => $game->id, 'period_id' => $period->id, 'user_id' => $user->id, 'star' => 0]);
        $user->stars()->create(['period_id' => $period->id, 'green_stars' => 1]);

        return $user;
    }

    public function test_deleting_the_scores_removes_the_runs_and_the_stars_but_keeps_other_players(): void
    {
        $user = $this->createPlayerWithScores();
        $other = $this->createPlayerWithScores();

        $deleted = app(ModerationService::class)->deleteScores($user);

        $this->assertSame(3, $deleted);
        $this->assertSame(0, $user->runs()->count());
        $this->assertSame(3, $user->runs()->onlyTrashed()->count());
        $this->assertSame(0, $user->gamePeriodStars()->count());
        $this->assertSame(0, $user->stars()->count());
        $this->assertFalse($user->fresh()->isBanned());

        $this->assertSame(3, $other->runs()->count());
        $this->assertSame(1, $other->stars()->count());
    }

    public function test_banning_deletes_the_scores_and_logs_the_player_out_with_the_reason(): void
    {
        $user = $this->createPlayerWithScores();
        $token = $user->createToken('kadokadeo')->plainTextToken;

        $this->withToken($token)->getJson('/api/user')->assertOk();

        app(ModerationService::class)->ban($user, BanReason::CHEAT);

        $this->assertTrue($user->fresh()->isBanned());
        $this->assertSame(BanReason::CHEAT, $user->fresh()->ban_reason);
        $this->assertSame(0, $user->runs()->count());

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/user')
            ->assertForbidden()
            ->assertJson(['banned' => true, 'message' => 'Votre compte a été banni pour tricherie.']);
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_an_unbanned_player_can_use_the_site_again(): void
    {
        $user = User::factory()->create();
        app(ModerationService::class)->ban($user, BanReason::MULTI_ACCOUNT);
        app(ModerationService::class)->unban($user);

        $token = $user->createToken('kadokadeo')->plainTextToken;
        $this->withToken($token)->getJson('/api/user')->assertOk();
        $this->assertFalse($user->fresh()->isBanned());
    }

    public function test_the_admin_bans_a_player_and_deletes_scores_from_the_panel(): void
    {
        $this->actingAs(User::factory()->create(['is_admin' => true]));
        $cheater = $this->createPlayerWithScores();
        $other = $this->createPlayerWithScores();

        Livewire::test(ListUsers::class)
            ->callTableAction('ban', $cheater, ['reason' => BanReason::MULTI_ACCOUNT->value])
            ->assertHasNoTableActionErrors();

        $this->assertSame(BanReason::MULTI_ACCOUNT, $cheater->fresh()->ban_reason);
        $this->assertSame(0, $cheater->runs()->count());

        Livewire::test(EditUser::class, ['record' => $other->getRouteKey()])
            ->callAction('deleteScores');

        $this->assertSame(0, $other->runs()->count());
        $this->assertFalse($other->fresh()->isBanned());
    }
}
