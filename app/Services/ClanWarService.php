<?php

namespace App\Services;

use App\Enums\ClanActionType;
use App\Enums\ClanAttackStatus;
use App\Enums\ClanBonusType;
use App\Enums\ClanPhase;
use App\Exceptions\ClanException;
use App\Models\Clan;
use App\Models\ClanAction;
use App\Models\ClanAttack;
use App\Models\ClanBonus;
use App\Models\Game;
use App\Models\Period;
use App\Models\Run;
use App\Models\User;
use Illuminate\Support\Facades\DB;

// the attacks and defenses of the clans: the score of an attack must be beaten by the attacked clan within
// kado.clans.attack_hours, otherwise the attacker wins points and the defender loses as many
class ClanWarService
{
    // a clan run asked but not begun after this time is forgotten
    public const ACTION_TTL_MINUTES = 15;

    public function __construct(private readonly ClanService $clanService) {}

    public function startAttack(User $user, Clan $defender, Game $game): ClanAction
    {
        $period = $this->clanService->assertPhase(ClanPhase::WAR, 'Les attaques ne sont possibles que pendant la période offensive.');
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
        if (now()->gte($this->clanService->attacksLockedAt($period))) {
            throw new ClanException('Plus aucune attaque ne peut être lancée avant la fin de la période.');
        }

        $attackerScore = $this->clanService->warScore($clan, $period);
        $defenderScore = $this->clanService->warScore($defender, $period);
        if ($this->clanService->isProtected($attackerScore, $defenderScore)) {
            throw new ClanException('Ce clan est protégé de vos attaques : son score est trop éloigné du vôtre.');
        }

        // one attack at a time, two with the "Double attaque" option given by the leader
        $bonus = null;
        if ($this->runningAttacksCount($user) >= 1) {
            $bonus = $this->availableBonus($user, $clan, $period, ClanBonusType::DOUBLE_ATTACK);
            if (!$bonus || $this->runningAttacksCount($user) >= 2) {
                throw new ClanException('Vous avez déjà une attaque en cours. Vous pouvez annuler votre attaque depuis la page statut de votre clan.');
            }
        }

        return ClanAction::query()->create([
            'clan_id' => $clan->id,
            'user_id' => $user->id,
            'game_id' => $game->id,
            'type' => ClanActionType::ATTACK,
            'defender_clan_id' => $defender->id,
            'clan_bonus_id' => $bonus?->id,
        ]);
    }

    public function startDefense(User $user, ClanAttack $attack, bool $superDefense = false): ClanAction
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
        if ($this->runningAttacksCount($user) > 0) {
            throw new ClanException('Vous ne pouvez pas défendre tant que vous avez une attaque en cours.');
        }

        $bonus = null;
        if ($superDefense) {
            $bonus = $this->availableBonus($user, $clan, $attack->period, ClanBonusType::SUPER_DEFENSE);
            if (!$bonus) {
                throw new ClanException('Vous ne disposez pas de l\'option Défense 120%.');
            }
        }

        return ClanAction::query()->create([
            'clan_id' => $clan->id,
            'user_id' => $user->id,
            'game_id' => $attack->game_id,
            'type' => ClanActionType::DEFENSE,
            'clan_attack_id' => $attack->id,
            'clan_bonus_id' => $bonus?->id,
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
        $period = $run->period ?? $this->clanService->currentPeriod();
        if (!$period || $this->clanService->phase($period) !== ClanPhase::WAR || now()->gte($this->clanService->attacksLockedAt($period))) {
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
            $action->bonus?->update(['used_at' => now()]);
            $this->clanService->memberStat($action->clan_id, $action->user_id, $period->id)->increment('attacks');
        });

        return 'launched';
    }

    // the attack is repelled when its score is beaten before its end
    public function completeDefense(ClanAction $action, Run $run): string
    {
        return DB::transaction(function () use ($action, $run) {
            $attack = ClanAttack::query()->lockForUpdate()->findOrFail($action->clan_attack_id);
            $score = $run->score;
            if ($action->bonus) {
                $action->bonus->update(['used_at' => now()]);
                $score = (int) floor($score * 1.2);
            }

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

    // the attacks not repelled in time are won (all the attacks of a closed period too)
    public function resolveExpired(?Period $closedPeriod = null): int
    {
        $query = ClanAttack::query()->active();
        $closedPeriod
            ? $query->where('period_id', $closedPeriod->id)
            : $query->where('expires_at', '<=', now());

        $count = 0;
        foreach ($query->pluck('id') as $attackId) {
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

    // his attacks waiting for a defense, and the attacks he is about to play
    public function runningAttacksCount(User $user): int
    {
        return ClanAttack::query()->active()->where('attacker_user_id', $user->id)->count()
            + $this->pendingActions($user, ClanActionType::ATTACK)->count();
    }

    public function pendingActions(User $user, ClanActionType $type)
    {
        return ClanAction::query()
            ->where('user_id', $user->id)
            ->where('type', $type)
            ->whereNull('run_id')
            ->whereNull('completed_at')
            ->where('created_at', '>=', now()->subMinutes(self::ACTION_TTL_MINUTES));
    }

    // an option given to the player by the leader (or not given yet, for the leader himself), not reserved by a run
    public function availableBonus(User $user, Clan $clan, Period $period, ClanBonusType $type): ?ClanBonus
    {
        return ClanBonus::query()
            ->available()
            ->where('clan_id', $clan->id)
            ->where('period_id', $period->id)
            ->where('type', $type)
            ->where(function ($query) use ($user, $clan) {
                $query->where('assigned_user_id', $user->id);
                if ($clan->leader_id === $user->id) {
                    $query->orWhereNull('assigned_user_id');
                }
            })
            ->whereDoesntHave('actions', fn ($q) => $q->whereNull('completed_at')->where('created_at', '>=', now()->subMinutes(self::ACTION_TTL_MINUTES)))
            // the one given to him first
            ->orderByRaw('assigned_user_id is null')
            ->first();
    }
}
