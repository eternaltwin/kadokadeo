<?php

namespace App\Services;

use App\Enums\ClanActionType;
use App\Enums\ClanAttackStatus;
use App\Enums\ClanCombatRole;
use App\Exceptions\ClanException;
use App\Models\Clan;
use App\Models\ClanAction;
use App\Models\ClanAttack;
use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Models\User;
use Illuminate\Support\Facades\DB;

// the attacks and defenses of the clans: the score of an attack must be beaten by the attacked clan within
// kado.clans.attack_hours, otherwise the attacker wins points and the defender loses as many. A repelled attack costs
// nothing to the attacker. One attack at a time by player (two for an "Attaquant"), as many received as can be.
class ClanWarService
{
    // a clan run asked but not begun after this time is forgotten
    public const ACTION_TTL_MINUTES = 15;

    public function __construct(private readonly ClanService $clanService) {}

    public function startAttack(User $user, Clan $defender, Game $game): ClanAction
    {
        $period = $this->clanService->assertPeriod();
        $clan = $this->clanService->clanOf($user);
        if (!$clan) {
            throw new ClanException('Vous devez faire partie d\'un clan pour attaquer.');
        }
        if ($clan->id === $defender->id) {
            throw new ClanException('Vous ne pouvez pas attaquer votre propre clan.');
        }
        if (!$game->is_active) {
            throw new ClanException('Ce jeu n\'est pas disponible.');
        }
        $attackerScore = $this->clanService->warScore($clan, $period);
        $defenderScore = $this->clanService->warScore($defender, $period);
        if ($this->clanService->isProtected($attackerScore, $defenderScore)) {
            throw new ClanException('Ce clan est protégé de vos attaques : son score est trop éloigné du vôtre.');
        }

        $this->clanService->forgetUnplayedActions($user);
        if ($this->runningAttacksCount($user) >= $this->maxAttacks($user, $clan)) {
            throw new ClanException('Vous avez déjà le maximum d\'attaques en cours. Vous pouvez améliorer ou annuler une attaque depuis la page statut de votre clan.');
        }

        return ClanAction::query()->create([
            'clan_id' => $clan->id,
            'user_id' => $user->id,
            'game_id' => $game->id,
            'type' => ClanActionType::ATTACK,
            'defender_clan_id' => $defender->id,
        ]);
    }

    // a new run on the game of his attack: its score replaces the score of the attack only if it is higher
    public function startImprovement(User $user, ClanAttack $attack): ClanAction
    {
        $this->resolveExpired();
        $attack->refresh();
        if ($attack->attacker_user_id !== $user->id) {
            throw new ClanException('Seul l\'attaquant peut améliorer son attaque.');
        }
        if ($attack->status !== ClanAttackStatus::ACTIVE) {
            throw new ClanException('Cette attaque est terminée.');
        }
        $this->clanService->forgetUnplayedActions($user);

        return ClanAction::query()->create([
            'clan_id' => $attack->attacker_clan_id,
            'user_id' => $user->id,
            'game_id' => $attack->game_id,
            'type' => ClanActionType::ATTACK,
            'defender_clan_id' => $attack->defender_clan_id,
            'clan_attack_id' => $attack->id,
        ]);
    }

    public function startDefense(User $user, ClanAttack $attack): ClanAction
    {
        $this->resolveExpired();
        $attack->refresh();

        $clan = $this->clanService->clanOf($user);
        if (!$clan || $clan->id !== $attack->defender_clan_id) {
            throw new ClanException('Seuls les membres du clan attaqué peuvent défendre.');
        }
        if ($attack->status !== ClanAttackStatus::ACTIVE) {
            throw new ClanException('Cette attaque est terminée.');
        }
        $this->clanService->forgetUnplayedActions($user);
        // a "Défenseur" defends while he attacks
        if ($this->runningAttacksCount($user) > 0 && $this->clanService->combatRoleOf($user, $clan) !== ClanCombatRole::DEFENDER) {
            throw new ClanException('Vous ne pouvez pas défendre tant que vous avez une attaque en cours.');
        }

        return ClanAction::query()->create([
            'clan_id' => $clan->id,
            'user_id' => $user->id,
            'game_id' => $attack->game_id,
            'type' => ClanActionType::DEFENSE,
            'clan_attack_id' => $attack->id,
        ]);
    }

    public function cancelAttack(User $user, ClanAttack $attack): void
    {
        if ($attack->attacker_user_id !== $user->id) {
            throw new ClanException('Seul l\'attaquant peut annuler son attaque.');
        }

        DB::transaction(function () use ($attack) {
            $attack = ClanAttack::query()->lockForUpdate()->findOrFail($attack->id);
            if ($attack->status !== ClanAttackStatus::ACTIVE) {
                throw new ClanException('Cette attaque est terminée.');
            }

            $attack->update(['status' => ClanAttackStatus::CANCELLED, 'resolved_at' => now()]);
        });
    }

    // the score of the attack run becomes the attack
    public function completeAttack(ClanAction $action, Run $run): string
    {
        if ($action->clan_attack_id) {
            return $this->completeImprovement($action, $run);
        }

        $period = $run->period ?? $this->clanService->currentPeriod();
        // the period ended during the run: the tournament started again
        if (!$period || $period->end_at->isPast()) {
            return 'too_late';
        }

        DB::transaction(function () use ($action, $run, $period) {
            ClanAttack::query()->create([
                'period_id' => $period->id,
                'game_id' => $run->game_id,
                'attacker_clan_id' => $action->clan_id,
                'attacker_user_id' => $action->user_id,
                'defender_clan_id' => $action->defender_clan_id,
                'run_id' => $run->id,
                'score' => $run->score,
                'status' => ClanAttackStatus::ACTIVE,
                'expires_at' => now()->addHours((int) config('kado.clans.attack_hours')),
            ]);
            $this->clanService->memberStat($action->clan_id, $action->user_id, $period->id)->increment('attacks');
        });

        return 'launched';
    }

    // a lower score leaves the attack as it was (the time to beat it does not change)
    private function completeImprovement(ClanAction $action, Run $run): string
    {
        return DB::transaction(function () use ($action, $run) {
            $attack = ClanAttack::query()->lockForUpdate()->findOrFail($action->clan_attack_id);
            if ($attack->status !== ClanAttackStatus::ACTIVE || $attack->expires_at->isPast()) {
                return 'too_late';
            }
            if ($run->score <= $attack->score) {
                return 'not_improved';
            }

            $attack->update(['score' => $run->score, 'run_id' => $run->id]);

            return 'improved';
        });
    }

    // the attack is repelled when its score is beaten before its end
    public function completeDefense(ClanAction $action, Run $run): string
    {
        return DB::transaction(function () use ($action, $run) {
            $attack = ClanAttack::query()->lockForUpdate()->findOrFail($action->clan_attack_id);
            $score = $run->score;

            $this->clanService->memberStat($action->clan_id, $action->user_id, $attack->period_id)->increment('defenses');

            if ($attack->status !== ClanAttackStatus::ACTIVE || $attack->expires_at->isPast()) {
                return 'too_late';
            }
            if ($score <= $attack->score) {
                return 'failed';
            }

            $period = $attack->period;
            $saved = $this->clanService->attackPoints(
                $this->clanService->periodScore($attack->attackerClan, $period)->war_score,
                $this->clanService->periodScore($attack->defenderClan, $period)->war_score,
            );
            $attack->update([
                'status' => ClanAttackStatus::REPELLED,
                'defender_user_id' => $action->user_id,
                'defense_run_id' => $run->id,
                'resolved_at' => now(),
            ]);
            $this->clanService->periodScore($attack->defenderClan, $period)->increment('defenses_won');
            $stat = $this->clanService->memberStat($action->clan_id, $action->user_id, $period->id);
            $stat->increment('defenses_won');
            $stat->increment('performance', $saved);

            return 'repelled';
        });
    }

    // the attacks of a closed period still waiting for a defense count for nothing: the scores start again from 0
    public function cancelUnfinished(Period $period): void
    {
        ClanAttack::query()
            ->active()
            ->where('period_id', $period->id)
            ->update(['status' => ClanAttackStatus::CANCELLED, 'resolved_at' => now()]);
    }

    // the attacks not repelled in time are won
    public function resolveExpired(): int
    {
        $count = 0;
        $attackIds = ClanAttack::query()->active()->where('expires_at', '<=', now())->pluck('id');
        foreach ($attackIds as $attackId) {
            DB::transaction(function () use ($attackId, &$count) {
                $attack = ClanAttack::query()->lockForUpdate()->find($attackId);
                if (!$attack || $attack->status !== ClanAttackStatus::ACTIVE) {
                    return;
                }

                $period = $attack->period;
                $attackerScore = $this->clanService->periodScore($attack->attackerClan, $period);
                $defenderScore = $this->clanService->periodScore($attack->defenderClan, $period);
                $points = $this->clanService->attackPoints($attackerScore->war_score, $defenderScore->war_score);

                $attack->update(['status' => ClanAttackStatus::WON, 'points' => $points, 'resolved_at' => now()]);
                $attackerScore->increment('war_score', $points);
                $attackerScore->increment('attacks_won');
                $defenderScore->update([
                    'war_score' => max(0, $defenderScore->war_score - $points),
                    'attacks_lost' => $defenderScore->attacks_lost + 1,
                ]);
                $stat = $this->clanService->memberStat($attack->attacker_clan_id, $attack->attacker_user_id, $period->id);
                $stat->increment('attacks_won');
                $stat->increment('performance', $points);
                $count++;
            });
        }

        return $count;
    }

    // his attacks waiting for a defense, and the new attack runs he is playing (begun less than an hour ago)
    public function runningAttacksCount(User $user): int
    {
        return ClanAttack::query()->active()->where('attacker_user_id', $user->id)->count()
            + ClanAction::query()
                ->where('user_id', $user->id)
                ->where('type', ClanActionType::ATTACK)
                ->whereNull('clan_attack_id')
                ->whereNotNull('run_id')
                ->whereNull('completed_at')
                ->where('created_at', '>=', now()->subHour())
                ->count();
    }

    // two for an "Attaquant", one for the others
    public function maxAttacks(User $user, Clan $clan): int
    {
        return $this->clanService->combatRoleOf($user, $clan) === ClanCombatRole::ATTACKER ? 2 : 1;
    }
}
