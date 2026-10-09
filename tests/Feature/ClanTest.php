<?php

namespace Tests\Feature;

use App\Enums\ClanAttackStatus;
use App\Enums\ClanBonusType;
use App\Models\Clan;
use App\Models\ClanAttack;
use App\Models\ClanBonus;
use App\Models\ClanMemberStat;
use App\Models\ClanMission;
use App\Models\ClanPeriodScore;
use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Models\User;
use App\Services\ClanMissionService;
use App\Services\ClanPeriodService;
use App\Services\ClanRunService;
use App\Services\ClanService;
use App\Services\ClanWarService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ClanTest extends TestCase
{
    use RefreshDatabase;

    // day 2 of the period
    private function period(): Period
    {
        return Period::factory()->create(['start_at' => now()->subDay()->startOfDay(), 'end_at' => now()->addDays(12)->endOfDay()]);
    }

    // a clan run: the action asked on the clan pages, then a run of the game ended with this score
    private function playClanRun(User $user, Game $game, Period $period, int $score): ?array
    {
        $run = Run::factory()->for($game)->for($user)->for($period)->create(['score' => 0, 'completed_at' => null]);
        app(ClanRunService::class)->bindRun($run);
        $run->update(['score' => $score, 'completed_at' => now()]);

        return app(ClanRunService::class)->handleRunCompleted($run->fresh());
    }

    public function test_a_player_creates_a_clan_and_accepts_an_application(): void
    {
        $this->period();
        $leader = User::factory()->create();
        $player = User::factory()->create();

        Sanctum::actingAs($leader);
        $clanId = $this->postJson('/api/clans', ['name' => 'Boule de neige'])->assertCreated()->json('data.id');

        Sanctum::actingAs($player);
        $applicationId = $this->postJson("/api/clans/{$clanId}/applications", ['message' => 'Salut !'])->assertCreated()->json('data.id');
        $this->postJson("/api/clans/{$clanId}/applications")->assertStatus(422);

        Sanctum::actingAs($leader);
        $this->getJson("/api/clans/{$clanId}/applications")->assertOk()->assertJsonPath('data.0.message', 'Salut !');
        $this->postJson("/api/clan-applications/{$applicationId}/accept")->assertNoContent();

        $this->getJson("/api/clans/{$clanId}/members")->assertOk()->assertJsonCount(2, 'data');
        $this->getJson("/api/clans/{$clanId}")->assertOk()
            ->assertJsonPath('data.members_count', 2)
            ->assertJsonPath('data.viewer.is_leader', true);
    }

    public function test_the_leader_must_name_a_new_leader_before_leaving(): void
    {
        $this->period();
        $leader = User::factory()->create();
        $member = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $member->id]);

        Sanctum::actingAs($leader);
        $this->postJson('/api/clans/leave')->assertStatus(422);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/leader")->assertNoContent();
        $this->postJson('/api/clans/leave')->assertNoContent();
        $this->assertSame($member->id, $clan->fresh()->leader_id);

        // the last member leaving disbands the clan
        Sanctum::actingAs($member);
        $this->postJson('/api/clans/leave')->assertNoContent();
        $this->assertModelMissing($clan);
    }

    public function test_an_attack_not_repelled_in_time_wins_points_and_the_defender_loses_as_many(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        $defender = User::factory()->create();
        $clanA = Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader($defender)->create();
        ClanPeriodScore::query()->create(['clan_id' => $clanB->id, 'period_id' => $period->id, 'war_score' => 3]);
        $game = Game::factory()->create();

        Sanctum::actingAs($attacker);
        $this->postJson("/api/clans/{$clanB->id}/attacks", ['game_id' => $game->id])->assertCreated();
        // one attack at a time
        $this->postJson("/api/clans/{$clanB->id}/attacks", ['game_id' => $game->id])->assertStatus(422);

        $result = $this->playClanRun($attacker, $game, $period, 500);
        $this->assertSame('launched', $result['result']);
        $attack = ClanAttack::query()->sole();
        $this->assertSame(ClanAttackStatus::ACTIVE, $attack->status);
        $this->assertSame(500, $attack->score);

        $this->travel(13)->hours();
        $this->assertSame(1, app(ClanWarService::class)->resolveExpired());

        $attack->refresh();
        $points = app(ClanService::class)->attackPoints(0, 3);
        $this->assertSame(ClanAttackStatus::WON, $attack->status);
        $this->assertSame($points, $attack->points);
        $this->assertSame($points, ClanPeriodScore::query()->where('clan_id', $clanA->id)->value('war_score'));
        // never below zero
        $this->assertSame(max(0, 3 - $points), ClanPeriodScore::query()->where('clan_id', $clanB->id)->value('war_score'));
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $attacker->id, 'attacks' => 1, 'attacks_won' => 1, 'performance' => $points]);
    }

    public function test_a_better_score_repels_the_attack_but_not_while_the_defender_attacks(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        $defender = User::factory()->create();
        $clanA = Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader($defender)->create();
        $game = Game::factory()->create();
        $warService = app(ClanWarService::class);

        $warService->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 500);
        $attack = ClanAttack::query()->sole();

        // the attacker can't defend his own attack, and a defender with an attack in progress can't defend
        $warService->startAttack($defender, $clanA, Game::factory()->create());
        Sanctum::actingAs($defender);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertStatus(422)
            ->assertJsonPath('message', 'Vous ne pouvez pas défendre tant que vous avez une attaque en cours.');

        $this->travel(20)->minutes(); // the attack he asked for is forgotten
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertCreated();
        $this->assertSame('failed', $this->playClanRun($defender, $game, $period, 500)['result']);

        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertCreated();
        $this->assertSame('repelled', $this->playClanRun($defender, $game, $period, 501)['result']);
        $this->assertSame(ClanAttackStatus::REPELLED, $attack->fresh()->status);
        $this->assertSame(1, ClanPeriodScore::query()->where('clan_id', $clanB->id)->value('defenses_won'));
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $defender->id, 'defenses' => 2, 'defenses_won' => 1]);
    }

    public function test_the_super_defense_option_counts_the_score_for_120_percent(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        $leader = User::factory()->create();
        $member = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader($leader)->create();
        $clanB->members()->create(['user_id' => $member->id]);
        $game = Game::factory()->create();
        $bonus = ClanBonus::query()->create(['clan_id' => $clanB->id, 'period_id' => $period->id, 'type' => ClanBonusType::SUPER_DEFENSE]);

        app(ClanWarService::class)->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 1000);
        $attack = ClanAttack::query()->sole();

        Sanctum::actingAs($member);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend", ['super_defense' => true])->assertStatus(422);
        Sanctum::actingAs($leader);
        $this->postJson("/api/clan-bonuses/{$bonus->id}/assign", ['user' => $member->etwin_id])->assertNoContent();
        Sanctum::actingAs($member);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend", ['super_defense' => true])->assertCreated();

        $this->assertSame('repelled', $this->playClanRun($member, $game, $period, 900)['result']);
        $this->assertNotNull($bonus->fresh()->used_at);
    }

    public function test_clans_too_far_apart_are_protected(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $strong = Clan::factory()->withLeader()->create();
        ClanPeriodScore::query()->create(['clan_id' => $strong->id, 'period_id' => $period->id, 'war_score' => 500]);
        $game = Game::factory()->create();

        Sanctum::actingAs($attacker);
        $this->postJson("/api/clans/{$strong->id}/attacks", ['game_id' => $game->id])->assertStatus(422);
        $this->getJson("/api/clans/{$strong->id}")->assertOk()
            ->assertJsonPath('data.viewer.attack_blocked', 'Ce clan est protégé de vos attaques : son score est trop éloigné du vôtre.');
    }

    // attacks any time of the period, from its first day; the next period starts again from 0
    public function test_the_attacks_of_the_first_day_and_the_reset_of_the_next_period(): void
    {
        $period = Period::factory()->create(['start_at' => now()->startOfDay(), 'end_at' => now()->addDays(13)->endOfDay()]);
        $attacker = User::factory()->create();
        $clanA = Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader()->create();
        $game = Game::factory()->create();
        $warService = app(ClanWarService::class);
        $bonus = ClanBonus::query()->create(['clan_id' => $clanA->id, 'period_id' => $period->id, 'type' => ClanBonusType::DOUBLE_ATTACK]);

        // an attack the first day, won
        $warService->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 100);
        $this->travel(13)->hours();
        $this->assertSame(1, $warService->resolveExpired());

        // two attacks at the same time with the "Double attaque" option, launched a few hours before the end
        $this->travelTo($period->end_at->clone()->subHours(2));
        $warService->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 100);
        $warService->startAttack($attacker, $clanB, $game);
        $this->assertSame('launched', $this->playClanRun($attacker, $game, $period, 100)['result']);
        $this->assertNotNull($bonus->fresh()->used_at);

        // the period ends: the attacks not over are cancelled
        $this->travelTo($period->end_at->clone()->addMinute());
        $nextPeriod = Period::factory()->create(['start_at' => now()->startOfDay(), 'end_at' => now()->addDays(13)->endOfDay()]);
        app(ClanPeriodService::class)->closePeriod($period);
        $this->assertSame(
            [ClanAttackStatus::WON, ClanAttackStatus::CANCELLED, ClanAttackStatus::CANCELLED],
            ClanAttack::query()->orderBy('id')->pluck('status')->all(),
        );
        $this->assertGreaterThan(0, ClanPeriodScore::query()->where('clan_id', $clanA->id)->where('period_id', $period->id)->value('war_score'));

        // day 1 of the next period: the same clans, scores at 0, attacks possible right away
        Sanctum::actingAs($attacker);
        $this->getJson("/api/clans/{$clanA->id}")->assertOk()
            ->assertJsonPath('data.stats.war_score', 0)
            ->assertJsonPath('tournament.period_id', $nextPeriod->id);
        $this->postJson("/api/clans/{$clanB->id}/attacks", ['game_id' => $game->id])->assertCreated();
    }

    public function test_a_mission_completed_gives_its_points_and_a_new_mission_follows(): void
    {
        config(['kado.clans.bonus_chance' => 1, 'kado.clans.mission_steps' => 2]);
        $period = $this->period();
        $leader = User::factory()->create();
        $member = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $member->id]);
        Game::factory()->count(3)->create();

        Sanctum::actingAs($member);
        $response = $this->getJson("/api/clans/{$clan->id}/missions")->assertOk()->assertJsonCount(2, 'data.mission.steps');
        $steps = $response->json('data.mission.steps');

        foreach ($steps as $step) {
            $this->postJson("/api/clan-mission-steps/{$step['id']}/play")->assertCreated();
            $game = Game::query()->find($step['game']['id']);
            $this->assertSame('failed', $this->playClanRun($member, $game, $period, $step['target_score'] - 1)['result']);
            $this->postJson("/api/clan-mission-steps/{$step['id']}/play")->assertCreated();
            $this->assertSame('completed', $this->playClanRun($member, $game, $period, $step['target_score'])['result']);
        }

        $mission = ClanMission::query()->where('number', 1)->sole();
        $points = array_sum(array_column($steps, 'points'));
        $this->assertSame(ClanMission::COMPLETED, $mission->status);
        $this->assertSame($points, $mission->points);
        $this->assertSame($points, ClanPeriodScore::query()->where('clan_id', $clan->id)->value('mission_score'));
        $this->assertSame(1, ClanBonus::query()->where('clan_id', $clan->id)->count());
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $member->id, 'mission_steps' => 2]);

        $this->getJson("/api/clans/{$clan->id}/missions")->assertOk()->assertJsonPath('data.mission.number', 2);
    }

    public function test_the_mission_bonuses_of_the_leader(): void
    {
        config(['kado.clans.bonus_chance' => 0, 'kado.clans.mission_steps' => 2]);
        $period = $this->period();
        $leader = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $games = Game::factory()->count(3)->create();
        $missionService = app(ClanMissionService::class);
        $bonus = fn (ClanBonusType $type) => ClanBonus::query()->create(['clan_id' => $clan->id, 'period_id' => $period->id, 'type' => $type]);

        $mission = $missionService->currentMission($clan);
        // "Jeu cool": the game is in the next missions
        $missionService->useBonus($leader, $bonus(ClanBonusType::FORCE_GAME), ['game_id' => $games[0]->id]);
        // "Double points" then "Mission suivante": the next mission is worth twice its points
        $missionService->useBonus($leader, $bonus(ClanBonusType::DOUBLE_POINTS));
        $missionService->useBonus($leader, $bonus(ClanBonusType::NEXT_MISSION));
        $this->assertSame(ClanMission::SKIPPED, $mission->fresh()->status);

        $next = $missionService->currentMission($clan);
        $this->assertSame(2, $next->number);
        $this->assertTrue($next->double_points);
        $this->assertTrue($next->steps->pluck('game_id')->contains($games[0]->id));

        // "Passe étape" on every step completes the mission, without the points of the skipped steps
        foreach ($next->steps as $step) {
            $missionService->useBonus($leader, $bonus(ClanBonusType::SKIP_STEP), ['step_id' => $step->id]);
        }
        $this->assertSame(ClanMission::COMPLETED, $next->fresh()->status);
        $this->assertSame(0, $next->fresh()->points);

        $member = User::factory()->create();
        $clan->members()->create(['user_id' => $member->id]);
        $this->expectExceptionMessage('Seul le chef de clan peut faire ça.');
        $missionService->useBonus($member, $bonus(ClanBonusType::MORE_TIME));
    }

    public function test_the_end_of_the_period_shares_the_rewards_between_the_members_once(): void
    {
        $period = $this->period();
        $leader = User::factory()->create(['kado_points' => 0]);
        $member = User::factory()->create(['kado_points' => 0]);
        $first = Clan::factory()->withLeader($leader)->create();
        $first->members()->create(['user_id' => $member->id]);
        $second = Clan::factory()->withLeader()->create();
        Clan::factory()->withLeader()->create(); // no score: not ranked
        ClanPeriodScore::query()->create(['clan_id' => $first->id, 'period_id' => $period->id, 'war_score' => 20, 'mission_score' => 5]);
        ClanPeriodScore::query()->create(['clan_id' => $second->id, 'period_id' => $period->id, 'war_score' => 10, 'mission_score' => 50]);

        app(ClanPeriodService::class)->closePeriod($period);
        app(ClanPeriodService::class)->closePeriod($period);

        $score = ClanPeriodScore::query()->where('clan_id', $first->id)->sole();
        $this->assertSame(1, $score->war_rank);
        $this->assertSame(2, $score->mission_rank);
        $expected = intdiv(150000 + 100000, 2);
        $this->assertSame($expected, $leader->fresh()->kado_points);
        $this->assertSame($expected, $member->fresh()->kado_points);
        $this->assertSame(3, ClanMemberStat::query()->whereNotNull('user_point_id')->count());
        $this->assertDatabaseHas('user_points', ['user_id' => $member->id, 'delta' => $expected, 'reason' => 'clan ranking']);
    }

    public function test_the_next_run_begun_on_the_game_is_bound_to_the_clan_action(): void
    {
        $this->period();
        $attacker = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $defender = Clan::factory()->withLeader()->create();
        $game = Game::factory()->create();

        Sanctum::actingAs($attacker);
        $actionId = $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $game->id])->assertCreated()->json('data.id');
        $this->getJson("/api/clan-actions/{$actionId}")->assertOk()->assertJsonPath('data.is_open', true);

        $runId = $this->postJson("/api/runs/games/{$game->id}")->assertSuccessful()->json('data.run_id');

        $this->assertDatabaseHas('clan_actions', ['id' => $actionId, 'run_id' => $runId]);
        $this->getJson("/api/clan-actions/{$actionId}")->assertOk()->assertJsonPath('data.is_open', false);
        // the next one is a normal run
        $otherRunId = $this->postJson("/api/runs/games/{$game->id}")->assertSuccessful()->json('data.run_id');
        $this->assertDatabaseMissing('clan_actions', ['run_id' => $otherRunId]);
    }

    public function test_the_ranking_and_the_overview(): void
    {
        $period = $this->period();
        $user = User::factory()->create();
        $mine = Clan::factory()->withLeader($user)->create(['name' => 'Les pirates']);
        $best = Clan::factory()->withLeader()->create(['name' => 'Dino RPG']);
        ClanPeriodScore::query()->create(['clan_id' => $best->id, 'period_id' => $period->id, 'war_score' => 42]);

        Sanctum::actingAs($user);
        $this->getJson('/api/clans')->assertOk()
            ->assertJsonPath('data.0.name', 'Dino RPG')
            ->assertJsonPath('data.0.rank', 1)
            ->assertJsonPath('data.1.name', 'Les pirates')
            ->assertJsonPath('tournament.period_id', $period->id);
        $this->getJson('/api/clans?q=pira')->assertOk()->assertJsonPath('data.0.rank', 2);
        $this->getJson('/api/clans/overview')->assertOk()
            ->assertJsonPath('data.clan.id', $mine->id)
            ->assertJsonPath('data.top.0.id', $best->id);
    }
}
