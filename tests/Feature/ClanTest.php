<?php

namespace Tests\Feature;

use App\Enums\ClanAttackStatus;
use App\Enums\ClanBonusType;
use App\Enums\ClanCombatRole;
use App\Enums\ClanRole;
use App\Models\Clan;
use App\Models\ClanAction;
use App\Models\ClanAttack;
use App\Models\ClanBonus;
use App\Models\ClanMemberStat;
use App\Models\ClanMission;
use App\Models\ClanMissionStep;
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
        // a single application at a time
        $other = Clan::factory()->withLeader()->create();
        $this->postJson("/api/clans/{$other->id}/applications")->assertStatus(422)
            ->assertJsonPath('message', "Vous avez déjà une candidature en attente pour le clan Boule de neige. Retirez-la avant d'en envoyer une autre.");

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
        $result = $this->playClanRun($attacker, $game, $period, 500);
        $this->assertSame('launched', $result['result']);
        $attack = ClanAttack::query()->sole();
        $this->assertSame(ClanAttackStatus::ACTIVE, $attack->status);
        $this->assertSame(500, $attack->score);
        // one attack at a time
        $this->postJson("/api/clans/{$clanB->id}/attacks", ['game_id' => $game->id])->assertStatus(422);

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

        // a defender with an attack in progress can't defend
        $otherGame = Game::factory()->create();
        $warService->startAttack($defender, $clanA, $otherGame);
        $this->playClanRun($defender, $otherGame, $period, 10);
        Sanctum::actingAs($defender);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertStatus(422)
            ->assertJsonPath('message', 'Vous ne pouvez pas défendre tant que vous avez une attaque en cours.');

        // ... until he cancels it (only its attacker can)
        $ownAttackId = ClanAttack::query()->latest('id')->value('id');
        Sanctum::actingAs($attacker);
        $this->postJson("/api/clan-attacks/{$ownAttackId}/cancel")->assertStatus(422);
        Sanctum::actingAs($defender);
        $this->postJson("/api/clan-attacks/{$ownAttackId}/cancel")->assertNoContent();
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertCreated();
        $this->assertSame('failed', $this->playClanRun($defender, $game, $period, 500)['result']);

        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertCreated();
        $this->assertSame('repelled', $this->playClanRun($defender, $game, $period, 501)['result']);
        $this->assertSame(ClanAttackStatus::REPELLED, $attack->fresh()->status);
        $this->assertSame(1, ClanPeriodScore::query()->where('clan_id', $clanB->id)->value('defenses_won'));
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $defender->id, 'defenses' => 2, 'defenses_won' => 1]);
    }

    // an "Attaquant" has two attacks at a time, a "Défenseur" defends while he attacks, within the seats of the clan
    public function test_the_combat_roles(): void
    {
        $period = $this->period();
        $leader = User::factory()->create();
        $member = User::factory()->create();
        $other = User::factory()->create();
        $clanA = Clan::factory()->withLeader($leader)->create();
        $clanA->members()->create(['user_id' => $member->id]);
        $clanA->members()->create(['user_id' => $other->id]);
        $enemy = User::factory()->create();
        $clanB = Clan::factory()->withLeader($enemy)->create();
        $game = Game::factory()->create();
        $warService = app(ClanWarService::class);

        // 3 members: 1 seat of each
        Sanctum::actingAs($leader);
        $this->putJson("/api/clans/{$clanA->id}/members/{$member->etwin_id}/combat-role", ['combat_role' => 'attacker'])->assertNoContent();
        $this->putJson("/api/clans/{$clanA->id}/members/{$other->etwin_id}/combat-role", ['combat_role' => 'attacker'])->assertStatus(422)
            ->assertJsonPath('message', 'Tous les sièges de Attaquant sont pris (1 pour ce clan).');
        $this->putJson("/api/clans/{$clanA->id}/members/{$other->etwin_id}/combat-role", ['combat_role' => 'defender'])->assertNoContent();
        Sanctum::actingAs($member);
        $this->putJson("/api/clans/{$clanA->id}/members/{$other->etwin_id}/combat-role", ['combat_role' => null])->assertStatus(422);

        // the attacker: two attacks, not a third one
        foreach ([1, 2] as $i) {
            $warService->startAttack($member, $clanB, $game);
            $this->assertSame('launched', $this->playClanRun($member, $game, $period, 100)['result']);
        }
        Sanctum::actingAs($member);
        $this->postJson("/api/clans/{$clanB->id}/attacks", ['game_id' => $game->id])->assertStatus(422);

        // the defender defends while he attacks, the others don't
        $warService->startAttack($enemy, $clanA, $game);
        $this->playClanRun($enemy, $game, $period, 500);
        $attack = ClanAttack::query()->where('attacker_user_id', $enemy->id)->sole();
        $warService->startAttack($other, $clanB, $game);
        $this->playClanRun($other, $game, $period, 100);
        Sanctum::actingAs($member);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertStatus(422);
        Sanctum::actingAs($other);
        $this->postJson("/api/clan-attacks/{$attack->id}/defend")->assertCreated();
        $this->assertSame('repelled', $this->playClanRun($other, $game, $period, 501)['result']);
    }

    // a new run on the game of an attack: its score counts only if it is higher
    public function test_an_attack_is_improved_only_by_a_higher_score(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader()->create();
        $game = Game::factory()->create();

        app(ClanWarService::class)->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 500);
        $attack = ClanAttack::query()->sole();
        $expiresAt = $attack->expires_at;

        Sanctum::actingAs($attacker);
        $this->getJson("/api/clans/{$clanB->id}/status")->assertOk()->assertJsonPath('data.received.0.can_improve', true);
        $this->postJson("/api/clan-attacks/{$attack->id}/improve")->assertCreated();
        $this->assertSame('not_improved', $this->playClanRun($attacker, $game, $period, 400)['result']);
        $this->assertSame(500, $attack->fresh()->score);

        $actionId = $this->postJson("/api/clan-attacks/{$attack->id}/improve")->assertCreated()->json('data.id');
        $this->getJson("/api/clan-actions/{$actionId}")->assertOk()->assertJsonPath('data.is_improvement', true);
        $this->assertSame('improved', $this->playClanRun($attacker, $game, $period, 800)['result']);
        $attack->refresh();
        $this->assertSame(800, $attack->score);
        $this->assertTrue($expiresAt->eq($attack->expires_at));
        // still a single attack
        $this->assertDatabaseCount('clan_attacks', 1);
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $attacker->id, 'attacks' => 1]);

        // only by its attacker
        Sanctum::actingAs(User::factory()->create());
        $this->postJson("/api/clan-attacks/{$attack->id}/improve")->assertStatus(422);
    }

    // a kind of Elo: half the points against a clan of the same score, more against a stronger clan, shown before attacking
    public function test_the_points_of_an_attack(): void
    {
        $clanService = app(ClanService::class);
        $this->assertSame(5, $clanService->attackPoints(0, 0));
        $this->assertSame(10, $clanService->attackPoints(0, 100));
        $this->assertSame(1, $clanService->attackPoints(100, 0));
        $this->assertGreaterThan($clanService->attackPoints(20, 0), $clanService->attackPoints(20, 40));

        $period = $this->period();
        $attacker = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $clanB = Clan::factory()->withLeader()->create();
        ClanPeriodScore::query()->create(['clan_id' => $clanB->id, 'period_id' => $period->id, 'war_score' => 30]);

        Sanctum::actingAs($attacker);
        $this->getJson("/api/clans/{$clanB->id}")->assertOk()->assertJsonPath('data.viewer.attack_points', $clanService->attackPoints(0, 30));
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
        $clanA->members()->where('user_id', $attacker->id)->update(['combat_role' => ClanCombatRole::ATTACKER]);

        // an attack the first day, won
        $warService->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 100);
        $this->travel(13)->hours();
        $this->assertSame(1, $warService->resolveExpired());

        // two attacks at the same time (an "Attaquant"), launched a few hours before the end
        $this->travelTo($period->end_at->clone()->subHours(2));
        $warService->startAttack($attacker, $clanB, $game);
        $this->playClanRun($attacker, $game, $period, 100);
        $warService->startAttack($attacker, $clanB, $game);
        $this->assertSame('launched', $this->playClanRun($attacker, $game, $period, 100)['result']);

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

    public function test_a_mission_completed_gives_its_points_and_opens_the_next_one(): void
    {
        config(['kado.clans.bonus_chance' => 1]);
        $period = $this->period();
        $leader = User::factory()->create();
        $member = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $member->id]);
        Game::factory()->count(8)->create();

        // 5 steps for a clan of 2 members, and the "Jeu cool" and "Jeu caca" options given at the start of the period
        Sanctum::actingAs($member);
        $response = $this->getJson("/api/clans/{$clan->id}/missions")->assertOk()
            ->assertJsonCount(5, 'data.mission.steps')
            ->assertJsonPath('data.mission.reward', 10)
            ->assertJsonCount(2, 'data.bonuses');
        $this->assertEqualsCanonicalizing(['force_game', 'ban_game'], array_column($response->json('data.bonuses'), 'type'));
        $steps = $response->json('data.mission.steps');

        foreach ($steps as $step) {
            $this->postJson("/api/clan-mission-steps/{$step['id']}/play")->assertCreated();
            $game = Game::query()->find($step['game']['id']);
            $this->assertSame('failed', $this->playClanRun($member, $game, $period, $step['target_score'] - 1)['result']);
            $this->postJson("/api/clan-mission-steps/{$step['id']}/play")->assertCreated();
            $this->assertSame('completed', $this->playClanRun($member, $game, $period, $step['target_score'])['result']);
        }

        $mission = ClanMission::query()->where('number', 1)->sole();
        $this->assertSame(ClanMission::COMPLETED, $mission->status);
        $this->assertSame(10, $mission->points);
        $this->assertSame(10, ClanPeriodScore::query()->where('clan_id', $clan->id)->value('mission_score'));
        // an option won with the mission
        $this->assertSame(3, ClanBonus::query()->where('clan_id', $clan->id)->count());
        // 1 point by step in the ranking of the clan
        $this->assertDatabaseHas('clan_member_stats', ['user_id' => $member->id, 'mission_steps' => 5]);
        $this->getJson("/api/clans/{$clan->id}/members")->assertOk()
            ->assertJsonPath('data.0.user.etwin_id', $member->etwin_id)
            ->assertJsonPath('data.0.points', 5);

        // the next mission: fewer points, a higher palier of the stars
        $this->getJson("/api/clans/{$clan->id}/missions")->assertOk()
            ->assertJsonPath('data.mission.number', 2)
            ->assertJsonPath('data.mission.reward', 9);
    }

    public function test_the_steps_grow_with_the_members_of_the_clan(): void
    {
        $missionService = app(ClanMissionService::class);
        $this->assertSame(5, $missionService->stepsCount(1, 1));
        $this->assertSame(24, $missionService->stepsCount(50, 1));
        $this->assertSame(9, $missionService->stepsCount(11, 1));
        // fewer steps with each mission when kado.clans.mission_steps.ratio is below 1
        config(['kado.clans.mission_steps.ratio' => 0.9]);
        $this->assertLessThan($missionService->stepsCount(50, 1), $missionService->stepsCount(50, 5));

        $this->assertSame(10, $missionService->missionPoints(1));
        $this->assertSame(1, $missionService->missionPoints(100));
    }

    public function test_a_mission_not_finished_in_time_loses_a_point_by_step_missed_minus_one(): void
    {
        config(['kado.clans.bonus_chance' => 0]);
        $period = $this->period();
        $leader = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        Game::factory()->count(10)->create(['stars' => [1000, 2000, 3000]]);
        ClanPeriodScore::query()->create(['clan_id' => $clan->id, 'period_id' => $period->id, 'mission_score' => 20]);
        $missionService = app(ClanMissionService::class);

        // 5 steps, 1 completed: 4 missed, 3 points lost
        $mission = $missionService->currentMission($clan);
        $this->assertCount(5, $mission->steps);
        // the first palier: half the first star
        $this->assertSame([500], $mission->steps->pluck('target_score')->unique()->values()->all());
        $step = $mission->steps->first();
        $missionService->startStep($leader, $step);
        $this->assertSame('completed', $this->playClanRun($leader, $step->game, $period, $step->target_score)['result']);

        $this->travel(25)->hours();
        $next = $missionService->currentMission($clan);
        $this->assertSame(ClanMission::FAILED, $mission->fresh()->status);
        $this->assertSame(-3, $mission->fresh()->points);
        $this->assertSame(17, ClanPeriodScore::query()->where('clan_id', $clan->id)->value('mission_score'));
        // a new mission of the same number
        $this->assertSame(1, $next->number);

        // a single step missed: nothing lost
        $next->steps->slice(1)->each(fn (ClanMissionStep $step) => $step->update(['skipped' => true]));
        $missionService->loseMission($next, ClanMission::FAILED);
        $this->assertSame(17, ClanPeriodScore::query()->where('clan_id', $clan->id)->value('mission_score'));
    }

    public function test_the_paliers_get_higher_with_the_missions_completed(): void
    {
        config(['kado.clans.bonus_chance' => 0]);
        $period = $this->period();
        $leader = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        Game::factory()->count(6)->create(['stars' => [1000, 2000, 3000]]);
        $missionService = app(ClanMissionService::class);

        $targets = [];
        foreach (range(1, 12) as $number) {
            $mission = $missionService->currentMission($clan);
            $this->assertSame($number, $mission->number);
            $targets[$number] = $mission->steps->first()->target_score;
            foreach ($mission->steps as $step) {
                $missionService->startStep($leader, $step);
                $this->playClanRun($leader, $step->game, $period, $step->target_score);
            }
        }

        // one palier higher every 2 missions: half the first star, the first star, between the first and the second...
        $this->assertSame([1 => 500, 2 => 500, 3 => 1000, 4 => 1000, 5 => 1500, 7 => 2000, 9 => 2500, 11 => 3000, 12 => 3000], array_intersect_key($targets, array_flip([1, 2, 3, 4, 5, 7, 9, 11, 12])));
    }

    // the runs of the missions don't cost a game, the attacks and the defenses do
    public function test_the_runs_of_the_missions_are_free(): void
    {
        config(['kado.games_per_day' => 10]);
        $this->period();
        $player = User::factory()->create(['kado_games' => 0]);
        $clan = Clan::factory()->withLeader($player)->create();
        $defender = Clan::factory()->withLeader()->create();
        Game::factory()->count(6)->create();
        $mission = app(ClanMissionService::class)->currentMission($clan);
        $step = $mission->steps->first();

        Sanctum::actingAs($player);
        $this->postJson("/api/runs/games/{$step->game_id}")->assertForbidden();
        $this->postJson("/api/clan-mission-steps/{$step->id}/play")->assertCreated();
        $this->postJson("/api/runs/games/{$step->game_id}")->assertSuccessful();
        $this->assertSame(0, $player->fresh()->kado_games);

        $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $step->game_id])->assertCreated();
        $this->postJson("/api/runs/games/{$step->game_id}")->assertForbidden();

        $player->update(['kado_games' => 3]);
        $this->postJson("/api/runs/games/{$step->game_id}")->assertSuccessful();
        $this->assertSame(2, $player->fresh()->kado_games);
    }

    public function test_the_mission_bonuses_of_the_leader_and_his_right_hands(): void
    {
        config(['kado.clans.bonus_chance' => 0]);
        $period = $this->period();
        $leader = User::factory()->create();
        $rightHand = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $rightHand->id, 'role' => ClanRole::RIGHT_HAND]);
        $games = Game::factory()->count(8)->create();
        $missionService = app(ClanMissionService::class);
        $bonus = fn (ClanBonusType $type) => ClanBonus::query()->create(['clan_id' => $clan->id, 'period_id' => $period->id, 'type' => $type]);

        $mission = $missionService->currentMission($clan);
        // "Jeu cool": the game is in the next missions
        $missionService->useBonus($rightHand, $bonus(ClanBonusType::FORCE_GAME), ['game_id' => $games[0]->id]);
        // "Plus de temps"
        $expiresAt = $mission->expires_at;
        $missionService->useBonus($leader, $bonus(ClanBonusType::MORE_TIME));
        $this->assertTrue($expiresAt->clone()->addHours(6)->eq($mission->fresh()->expires_at));
        // "Mission suivante": a new mission of the same number, without losing points
        $missionService->useBonus($leader, $bonus(ClanBonusType::NEXT_MISSION));
        $this->assertSame(ClanMission::SKIPPED, $mission->fresh()->status);
        $this->assertSame(0, $mission->fresh()->points);

        $next = $missionService->currentMission($clan);
        $this->assertSame(1, $next->number);
        $this->assertTrue($next->steps->pluck('game_id')->contains($games[0]->id));

        // "Passe étape" on every step completes the mission
        foreach ($next->steps as $step) {
            $missionService->useBonus($leader, $bonus(ClanBonusType::SKIP_STEP), ['step_id' => $step->id]);
        }
        $this->assertSame(ClanMission::COMPLETED, $next->fresh()->status);
        $this->assertSame(10, ClanPeriodScore::query()->where('clan_id', $clan->id)->value('mission_score'));

        $member = User::factory()->create();
        $clan->members()->create(['user_id' => $member->id]);
        $this->expectExceptionMessage('Seuls le chef de clan et ses bras droits peuvent faire ça.');
        $missionService->useBonus($member, $bonus(ClanBonusType::MORE_TIME));
    }

    // bought by packs with Kado points, given to the clan, distributed by the leader and the right hands
    public function test_the_paid_clan_games(): void
    {
        $this->period();
        $leader = User::factory()->create(['kado_points' => 1000, 'kado_games' => 5]);
        $member = User::factory()->create(['kado_points' => 0]);
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $member->id]);

        Sanctum::actingAs($leader);
        $this->getJson('/api/clan-games')->assertOk()
            ->assertJsonPath('data.packs.3', ['count' => 50, 'price' => 1750, 'unit_price' => 35])
            ->assertJsonPath('data.clan.can_distribute', true);
        $this->postJson('/api/clan-games/buy', ['count' => 10])->assertNoContent();
        $this->postJson('/api/clan-games/buy', ['count' => 3])->assertStatus(422);
        $this->postJson('/api/clan-games/buy', ['count' => 50])->assertStatus(422)
            ->assertJsonPath('message', 'Vous n\'avez pas assez de points Kado pour acheter ces parties.');
        $leader->refresh();
        $this->assertSame(600, $leader->kado_points);
        $this->assertSame(10, $leader->clan_games);
        $this->assertDatabaseHas('user_points', ['user_id' => $leader->id, 'delta' => -400, 'reason' => 'clan games purchase']);

        // only the paid games can be given, not the games of the day
        $this->postJson("/api/clans/{$clan->id}/games/donate", ['count' => 11])->assertStatus(422);
        $this->postJson("/api/clans/{$clan->id}/games/donate", ['count' => 4])->assertNoContent();
        $this->assertSame(6, $leader->fresh()->clan_games);
        $this->assertSame(4, $clan->fresh()->clan_games);

        // distributed by the leader and the right hands only
        Sanctum::actingAs($member);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/games", ['count' => 1])->assertStatus(422);
        Sanctum::actingAs($leader);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/games", ['count' => 5])->assertStatus(422);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/games", ['count' => 3])->assertNoContent();
        $this->assertSame(3, $member->fresh()->clan_games);
        $this->assertSame(1, $clan->fresh()->clan_games);
        $this->getJson('/api/clan-games')->assertOk()
            ->assertJsonPath('data.clan.transfers.0.type', 'distribution')
            ->assertJsonPath('data.clan.transfers.1.type', 'donation');
    }

    // attacks and defenses: the games of the day first, then the paid clan games
    public function test_the_paid_clan_games_are_used_after_the_games_of_the_day(): void
    {
        config(['kado.games_per_day' => 10]);
        $this->period();
        $player = User::factory()->create(['kado_games' => 1, 'clan_games' => 1]);
        Clan::factory()->withLeader($player)->create();
        $defender = Clan::factory()->withLeader()->create();
        $game = Game::factory()->create();
        $attackRun = function () use ($defender, $game) {
            ClanAction::query()->delete();
            $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $game->id])->assertCreated();

            return $this->postJson("/api/runs/games/{$game->id}");
        };

        Sanctum::actingAs($player);
        $attackRun()->assertSuccessful();
        $this->assertSame([0, 1], [$player->fresh()->kado_games, $player->fresh()->clan_games]);
        $attackRun()->assertSuccessful();
        $this->assertSame([0, 0], [$player->fresh()->kado_games, $player->fresh()->clan_games]);
        $attackRun()->assertForbidden();

        // not for a normal run (no attack asked)
        ClanAction::query()->delete();
        $player->refresh()->update(['clan_games' => 1]);
        $this->postJson("/api/runs/games/{$game->id}")->assertForbidden();
        $this->assertSame(1, $player->fresh()->clan_games);
    }

    // the leader can do everything, a right hand everything but disband the clan and name a new leader
    public function test_the_roles_of_the_clan(): void
    {
        $this->period();
        $leader = User::factory()->create();
        $rightHand = User::factory()->create();
        $member = User::factory()->create();
        $player = User::factory()->create();
        $clan = Clan::factory()->withLeader($leader)->create();
        $clan->members()->create(['user_id' => $rightHand->id]);
        $clan->members()->create(['user_id' => $member->id]);

        Sanctum::actingAs($leader);
        $this->putJson("/api/clans/{$clan->id}/members/{$rightHand->etwin_id}/role", ['role' => 'right_hand'])->assertNoContent();
        $this->putJson("/api/clans/{$clan->id}/members/{$leader->etwin_id}/role", ['role' => 'member'])->assertStatus(422);

        Sanctum::actingAs($player);
        $applicationId = $this->postJson("/api/clans/{$clan->id}/applications")->assertCreated()->json('data.id');

        // the right hand manages the clan
        Sanctum::actingAs($rightHand);
        $this->getJson("/api/clans/{$clan->id}")->assertOk()
            ->assertJsonPath('data.viewer.can_manage', true)
            ->assertJsonPath('data.viewer.role', 'right_hand');
        $this->postJson("/api/clan-applications/{$applicationId}/accept")->assertNoContent();
        $this->putJson("/api/clans/{$clan->id}", ['is_recruiting' => false])->assertNoContent();
        $this->postJson("/api/clans/{$clan->id}/members/{$player->etwin_id}/kick")->assertNoContent();
        $this->postJson("/api/clans/{$clan->id}/members/{$leader->etwin_id}/kick")->assertStatus(422);
        // ... but does not disband it nor name a new leader
        $this->deleteJson("/api/clans/{$clan->id}")->assertStatus(422);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/leader")->assertStatus(422);

        // a member does not manage it
        Sanctum::actingAs($member);
        $this->getJson("/api/clans/{$clan->id}")->assertOk()->assertJsonPath('data.viewer.can_manage', false);
        $this->postJson("/api/clans/{$clan->id}/members/{$rightHand->etwin_id}/kick")->assertStatus(422);

        // a new leader: the former one becomes a right hand
        Sanctum::actingAs($leader);
        $this->postJson("/api/clans/{$clan->id}/members/{$member->etwin_id}/leader")->assertNoContent();
        $this->assertSame(ClanRole::RIGHT_HAND, app(ClanService::class)->roleOf($leader, $clan->fresh()));

        Sanctum::actingAs($member);
        $this->deleteJson("/api/clans/{$clan->id}")->assertNoContent();
        $this->assertModelMissing($clan);
        $this->assertDatabaseCount('clan_members', 0);
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

    // choosing a game then leaving the page (or choosing another game) does not count as an attack
    public function test_an_attack_asked_but_not_played_does_not_block_the_next_one(): void
    {
        $period = $this->period();
        $attacker = User::factory()->create();
        Clan::factory()->withLeader($attacker)->create();
        $defender = Clan::factory()->withLeader()->create();
        [$interwheel, $kanji] = Game::factory()->count(2)->create();

        Sanctum::actingAs($attacker);
        $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $interwheel->id])->assertCreated();
        $actionId = $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $kanji->id])->assertCreated()->json('data.id');
        $this->assertDatabaseCount('clan_actions', 1);

        // once the run of the attack is begun, it counts
        $this->postJson("/api/runs/games/{$kanji->id}")->assertSuccessful();
        $this->postJson("/api/clans/{$defender->id}/attacks", ['game_id' => $interwheel->id])->assertStatus(422);
        $this->assertDatabaseHas('clan_actions', ['id' => $actionId]);
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
