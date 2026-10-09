<?php

namespace App\Services;

use App\Exceptions\ClanException;
use App\Models\Clan;
use App\Models\ClanAction;
use App\Models\ClanApplication;
use App\Models\ClanMember;
use App\Models\ClanMemberStat;
use App\Models\ClanPeriodScore;
use App\Models\Period;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

// the clans (help of KadoKado): groups of 1 to 50 players. The tournament lasts a period (14 days): during all of it the
// clans attack each other and complete missions, then the scores, the missions and the options start again from 0 on the
// first day of the next period (the clans and their members stay).
class ClanService
{
    public function currentPeriod(): ?Period
    {
        return Period::current()->first();
    }

    public function tournamentInfo(): ?array
    {
        $period = $this->currentPeriod();
        if (!$period) {
            return null;
        }

        return [
            'period_id' => $period->id,
            'starts_at' => $period->start_at->toIso8601String(),
            'ends_at' => $period->end_at->toIso8601String(),
        ];
    }

    public function assertPeriod(): Period
    {
        return $this->currentPeriod() ?? throw new ClanException('Aucune période en cours.');
    }

    public function clanOf(User $user): ?Clan
    {
        return $user->clanMember()->first()?->clan;
    }

    public function isMember(User $user, Clan $clan): bool
    {
        return ClanMember::query()->where('clan_id', $clan->id)->where('user_id', $user->id)->exists();
    }

    public function assertMember(User $user, Clan $clan): void
    {
        if (!$this->isMember($user, $clan)) {
            throw new ClanException('Vous ne faites pas partie de ce clan.');
        }
    }

    public function assertLeader(User $user, Clan $clan): void
    {
        if ($clan->leader_id !== $user->id) {
            throw new ClanException('Seul le chef de clan peut faire ça.');
        }
    }

    // ---------------------------------------------------------------- membership

    public function create(User $user, string $name, ?string $description): Clan
    {
        if ($this->clanOf($user)) {
            throw new ClanException('Vous faites déjà partie d\'un clan.');
        }

        return DB::transaction(function () use ($user, $name, $description) {
            $clan = Clan::query()->create([
                'name' => $name,
                'description' => $description,
                'leader_id' => $user->id,
            ]);
            $clan->members()->create(['user_id' => $user->id]);
            ClanApplication::query()
                ->where('user_id', $user->id)
                ->where('status', ClanApplication::PENDING)
                ->update(['status' => ClanApplication::REFUSED]);

            return $clan;
        });
    }

    public function apply(User $user, Clan $clan, ?string $message): ClanApplication
    {
        if ($this->clanOf($user)) {
            throw new ClanException('Vous faites déjà partie d\'un clan.');
        }
        if (!$clan->is_recruiting) {
            throw new ClanException('Ce clan ne recrute pas pour le moment.');
        }
        if ($clan->members()->count() >= config('kado.clans.max_members')) {
            throw new ClanException('Ce clan est complet.');
        }
        $pending = $clan->applications()->where('user_id', $user->id)->where('status', ClanApplication::PENDING)->exists();
        if ($pending) {
            throw new ClanException('Vous avez déjà envoyé votre candidature à ce clan.');
        }

        return $clan->applications()->create([
            'user_id' => $user->id,
            'message' => $message,
            'status' => ClanApplication::PENDING,
        ]);
    }

    public function cancelApplication(User $user, ClanApplication $application): void
    {
        if ($application->user_id !== $user->id || $application->status !== ClanApplication::PENDING) {
            throw new ClanException('Cette candidature ne peut pas être annulée.');
        }

        $application->delete();
    }

    public function acceptApplication(User $leader, ClanApplication $application): void
    {
        $clan = $application->clan;
        $this->assertLeader($leader, $clan);

        if ($application->status !== ClanApplication::PENDING) {
            throw new ClanException('Cette candidature a déjà été traitée.');
        }

        DB::transaction(function () use ($clan, $application) {
            if ($clan->members()->lockForUpdate()->count() >= config('kado.clans.max_members')) {
                throw new ClanException('Ce clan est complet.');
            }
            if (ClanMember::query()->where('user_id', $application->user_id)->exists()) {
                $application->update(['status' => ClanApplication::REFUSED]);

                throw new ClanException('Ce joueur fait déjà partie d\'un clan.');
            }

            $clan->members()->create(['user_id' => $application->user_id]);
            $application->update(['status' => ClanApplication::ACCEPTED]);
            // his other applications are no longer needed
            ClanApplication::query()
                ->where('user_id', $application->user_id)
                ->where('status', ClanApplication::PENDING)
                ->update(['status' => ClanApplication::REFUSED]);
        });
    }

    public function refuseApplication(User $leader, ClanApplication $application): void
    {
        $this->assertLeader($leader, $application->clan);
        if ($application->status !== ClanApplication::PENDING) {
            throw new ClanException('Cette candidature a déjà été traitée.');
        }

        $application->update(['status' => ClanApplication::REFUSED]);
    }

    // the last member leaving disbands the clan; the leader must give the leadership to someone else first
    public function leave(User $user): void
    {
        $clan = $this->clanOf($user);
        if (!$clan) {
            throw new ClanException('Vous ne faites partie d\'aucun clan.');
        }

        $membersCount = $clan->members()->count();
        if ($clan->leader_id === $user->id && $membersCount > 1) {
            throw new ClanException('Vous devez d\'abord nommer un nouveau chef de clan.');
        }

        DB::transaction(function () use ($clan, $user, $membersCount) {
            $clan->members()->where('user_id', $user->id)->delete();
            if ($membersCount <= 1) {
                $clan->delete();
            }
        });
    }

    public function kick(User $leader, Clan $clan, User $member): void
    {
        $this->assertLeader($leader, $clan);
        if ($member->id === $leader->id) {
            throw new ClanException('Vous ne pouvez pas vous exclure vous-même.');
        }
        $this->assertMember($member, $clan);

        $clan->members()->where('user_id', $member->id)->delete();
    }

    public function transferLeadership(User $leader, Clan $clan, User $member): void
    {
        $this->assertLeader($leader, $clan);
        $this->assertMember($member, $clan);

        $clan->update(['leader_id' => $member->id]);
    }

    // ---------------------------------------------------------------- scores

    public function periodScore(Clan $clan, Period $period): ClanPeriodScore
    {
        $score = ClanPeriodScore::query()->firstOrCreate(['clan_id' => $clan->id, 'period_id' => $period->id]);

        // (the default values of the columns)
        return $score->wasRecentlyCreated ? $score->refresh() : $score;
    }

    // the clan runs he asked for but did not begin: a new one replaces them (he chose another game, left the page...)
    public function forgetUnplayedActions(User $user): void
    {
        ClanAction::query()
            ->where('user_id', $user->id)
            ->whereNull('run_id')
            ->whereNull('completed_at')
            ->delete();
    }

    public function warScore(Clan $clan, Period $period): int
    {
        return (int) (ClanPeriodScore::query()->where('clan_id', $clan->id)->where('period_id', $period->id)->value('war_score') ?? 0);
    }

    public function memberStat(int $clanId, int $userId, int $periodId): ClanMemberStat
    {
        $stat = ClanMemberStat::query()->firstOrCreate(['clan_id' => $clanId, 'user_id' => $userId, 'period_id' => $periodId]);

        return $stat->wasRecentlyCreated ? $stat->refresh() : $stat;
    }

    // 1 to max points: about the middle against a clan of the same score, more against a stronger clan
    public function attackPoints(int $attackerScore, int $defenderScore): int
    {
        $max = (int) config('kado.clans.attack_max_points');
        $range = max(1, (int) config('kado.clans.protection_range'));
        $points = (int) round(($max + 1) / 2 + ($defenderScore - $attackerScore) * ($max - 1) / 2 / $range);

        return max(1, min($max, $points));
    }

    public function isProtected(int $attackerScore, int $defenderScore): bool
    {
        return abs($attackerScore - $defenderScore) > (int) config('kado.clans.protection_range');
    }

    /**
     * The clans with their scores of the period (0 without any), best first.
     *
     * @param  'war'|'missions'  $ranking
     */
    public function rankingQuery(Period $period, string $ranking = 'war'): Builder
    {
        $column = $ranking === 'missions' ? 'mission_score' : 'war_score';

        return Clan::query()
            ->leftJoin('clan_period_scores', function ($join) use ($period) {
                $join->on('clan_period_scores.clan_id', '=', 'clans.id')
                    ->where('clan_period_scores.period_id', '=', $period->id);
            })
            ->select('clans.*')
            ->selectRaw('COALESCE(clan_period_scores.war_score, 0) as war_score')
            ->selectRaw('COALESCE(clan_period_scores.mission_score, 0) as mission_score')
            ->selectRaw('COALESCE(clan_period_scores.attacks_won, 0) as attacks_won')
            ->selectRaw('COALESCE(clan_period_scores.defenses_won, 0) as defenses_won')
            ->selectRaw('COALESCE(clan_period_scores.missions_completed, 0) as missions_completed')
            ->orderByRaw("COALESCE(clan_period_scores.{$column}, 0) desc")
            ->orderBy('clans.id');
    }

    public function rankOf(Clan $clan, Period $period, string $ranking = 'war'): int
    {
        $column = $ranking === 'missions' ? 'mission_score' : 'war_score';
        $score = (int) (ClanPeriodScore::query()->where('clan_id', $clan->id)->where('period_id', $period->id)->value($column) ?? 0);

        // same order as rankingQuery: score, then the oldest clan first
        $better = ClanPeriodScore::query()
            ->where('period_id', $period->id)
            ->where(function ($query) use ($column, $score, $clan) {
                $query->where($column, '>', $score)
                    ->orWhere(fn ($q) => $q->where($column, $score)->where('clan_id', '<', $clan->id));
            })
            ->count();

        // the clans without any score of the period are ranked after, by id
        if ($score === 0) {
            $better += Clan::query()
                ->where('id', '<', $clan->id)
                ->whereDoesntHave('periodScores', fn ($q) => $q->where('period_id', $period->id))
                ->count();
        }

        return $better + 1;
    }
}
