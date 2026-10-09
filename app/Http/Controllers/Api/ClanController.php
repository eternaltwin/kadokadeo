<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ClanAttackResource;
use App\Http\Resources\ClanListResource;
use App\Http\Resources\UserLightResource;
use App\Models\Clan;
use App\Models\ClanApplication;
use App\Models\ClanAttack;
use App\Models\ClanMember;
use App\Models\ClanMemberStat;
use App\Models\ClanPeriodScore;
use App\Services\ClanService;
use App\Services\ClanWarService;
use Illuminate\Http\Request;
use Illuminate\Routing\Controllers\HasMiddleware;
use Illuminate\Routing\Controllers\Middleware;
use Illuminate\Validation\Rule;

class ClanController extends Controller implements HasMiddleware
{
    public static function middleware()
    {
        return [
            new Middleware('auth:sanctum'),
        ];
    }

    public function __construct(
        private readonly ClanService $clanService,
        private readonly ClanWarService $warService,
    ) {}

    // the ranking of the clans of the current period ("Classement")
    public function index(Request $request)
    {
        $validated = $request->validate([
            'ranking' => ['sometimes', Rule::in(['war', 'missions'])],
            'q' => ['sometimes', 'nullable', 'string', 'max:32'],
        ]);
        $period = $this->clanService->currentPeriod();
        abort_unless($period, 404, 'Aucune période en cours.');
        $this->warService->resolveExpired();

        $ranking = $validated['ranking'] ?? 'war';
        $query = $this->clanService->rankingQuery($period, $ranking)->withCount('members');
        if (!empty($validated['q'])) {
            $query->where('clans.name', 'like', '%'.$validated['q'].'%');
        }

        $clans = $query->paginate(50);
        $clans->getCollection()->each(function (Clan $clan, int $index) use ($clans, $validated, $period, $ranking) {
            // in a search, the position in the whole ranking
            $clan->rank = empty($validated['q'])
                ? ($clans->currentPage() - 1) * $clans->perPage() + $index + 1
                : $this->clanService->rankOf($clan, $period, $ranking);
        });

        return ClanListResource::collection($clans)->additional(['tournament' => $this->clanService->tournamentInfo()]);
    }

    // what the menus need: the period of the tournament, the clan of the player, the top 3
    public function overview(Request $request)
    {
        $user = $request->user();
        $period = $this->clanService->currentPeriod();
        $clan = $this->clanService->clanOf($user);
        $top = $period
            ? $this->clanService->rankingQuery($period)->limit(3)->get()->each(fn ($c, $i) => $c->rank = $i + 1)
            : collect();

        return [
            'data' => [
                'tournament' => $this->clanService->tournamentInfo(),
                'clan' => $clan ? ['id' => $clan->id, 'name' => $clan->name, 'is_leader' => $clan->leader_id === $user->id] : null,
                'applications' => ClanApplication::query()
                    ->where('user_id', $user->id)
                    ->where('status', ClanApplication::PENDING)
                    ->with('clan:id,name')
                    ->get()
                    ->map(fn (ClanApplication $a) => ['id' => $a->id, 'clan' => ['id' => $a->clan->id, 'name' => $a->clan->name]]),
                'top' => ClanListResource::collection($top),
                // the tools of /clans/debug (kado.debug_tools)
                'debug' => (bool) config('kado.debug_tools'),
            ],
        ];
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'min:3', 'max:32', 'unique:clans,name'],
            'description' => ['nullable', 'string', 'max:5000'],
        ], [
            'name.unique' => 'Ce nom de clan est déjà pris.',
        ]);

        $clan = $this->clanService->create($request->user(), $validated['name'], $validated['description'] ?? null);

        return response()->json(['data' => ['id' => $clan->id]], 201);
    }

    // "Présentation"
    public function show(Request $request, Clan $clan)
    {
        $user = $request->user();
        $period = $this->clanService->currentPeriod();
        $this->warService->resolveExpired();
        $clan->load('leader')->loadCount('members');

        $score = $period ? ClanPeriodScore::query()->where('clan_id', $clan->id)->where('period_id', $period->id)->first() : null;
        $myClan = $this->clanService->clanOf($user);
        $isMember = $myClan?->id === $clan->id;

        return [
            'data' => [
                'id' => $clan->id,
                'name' => $clan->name,
                'description' => $clan->description,
                'is_recruiting' => $clan->is_recruiting,
                'created_at' => $clan->created_at?->toIso8601String(),
                'leader' => $clan->leader ? UserLightResource::make($clan->leader) : null,
                'members_count' => $clan->members_count,
                'max_members' => (int) config('kado.clans.max_members'),
                'stats' => [
                    'war_rank' => $period ? $this->clanService->rankOf($clan, $period) : null,
                    'war_score' => $score?->war_score ?? 0,
                    'mission_rank' => $period ? $this->clanService->rankOf($clan, $period, 'missions') : null,
                    'mission_score' => $score?->mission_score ?? 0,
                    'attacks_won' => $score?->attacks_won ?? 0,
                    'defenses_won' => $score?->defenses_won ?? 0,
                ],
                // "Période 191 : TOP 4 au classement des clans"
                'history' => ClanPeriodScore::query()
                    ->where('clan_id', $clan->id)
                    ->whereNotNull('closed_at')
                    ->orderByDesc('period_id')
                    ->limit(20)
                    ->get(['period_id', 'war_rank', 'mission_rank', 'war_score', 'mission_score', 'reward']),
                'viewer' => [
                    'is_member' => $isMember,
                    'is_leader' => $clan->leader_id === $user->id,
                    'has_clan' => $myClan !== null,
                    'application_id' => ClanApplication::query()
                        ->where('clan_id', $clan->id)
                        ->where('user_id', $user->id)
                        ->where('status', ClanApplication::PENDING)
                        ->value('id'),
                    'attack_blocked' => $this->attackBlockedReason($user, $myClan, $clan, $period),
                ],
            ],
            'tournament' => $this->clanService->tournamentInfo(),
        ];
    }

    public function update(Request $request, Clan $clan)
    {
        $this->clanService->assertLeader($request->user(), $clan);
        $validated = $request->validate([
            'description' => ['sometimes', 'nullable', 'string', 'max:5000'],
            'is_recruiting' => ['sometimes', 'boolean'],
        ]);
        $clan->update($validated);

        return response()->noContent();
    }

    // "Membres": what each member did for the clan during the period
    public function members(Request $request, Clan $clan)
    {
        $period = $this->clanService->currentPeriod();
        $stats = $period
            ? ClanMemberStat::query()->where('clan_id', $clan->id)->where('period_id', $period->id)->get()->keyBy('user_id')
            : collect();

        $members = ClanMember::query()
            ->where('clan_id', $clan->id)
            ->with('user')
            ->orderBy('created_at')
            ->get()
            ->map(function (ClanMember $member) use ($clan, $stats) {
                $stat = $stats->get($member->user_id);

                return [
                    'user' => UserLightResource::make($member->user),
                    'is_leader' => $clan->leader_id === $member->user_id,
                    'joined_at' => $member->created_at?->toIso8601String(),
                    'attacks' => $stat?->attacks ?? 0,
                    'attacks_won' => $stat?->attacks_won ?? 0,
                    'defenses' => $stat?->defenses ?? 0,
                    'defenses_won' => $stat?->defenses_won ?? 0,
                    'mission_steps' => $stat?->mission_steps ?? 0,
                    'performance' => $stat?->performance ?? 0,
                ];
            });

        return ['data' => $members];
    }

    // "Statut": the attacks launched by the clan and the attacks against it, during the period
    public function status(Request $request, Clan $clan)
    {
        $period = $this->clanService->currentPeriod();
        $this->warService->resolveExpired();
        $with = ['game', 'attackerUser', 'attackerClan', 'defenderClan', 'defenderUser'];
        $base = fn () => ClanAttack::query()
            ->with($with)
            ->where('period_id', $period?->id)
            ->orderByRaw("case when status = 'active' then 0 else 1 end")
            ->orderByDesc('id')
            ->limit(100);

        return [
            'data' => [
                'launched' => ClanAttackResource::collection($base()->where('attacker_clan_id', $clan->id)->get()),
                'received' => ClanAttackResource::collection($base()->where('defender_clan_id', $clan->id)->get()),
            ],
            'tournament' => $this->clanService->tournamentInfo(),
        ];
    }

    private function attackBlockedReason($user, ?Clan $myClan, Clan $clan, $period): ?string
    {
        if (!$myClan) {
            return 'Vous devez faire partie d\'un clan pour attaquer.';
        }
        if ($myClan->id === $clan->id) {
            return 'Vous ne pouvez pas attaquer votre propre clan.';
        }
        if (!$period) {
            return 'Aucune période en cours.';
        }
        $attackerScore = $this->clanService->warScore($myClan, $period);
        $defenderScore = $this->clanService->warScore($clan, $period);
        if ($this->clanService->isProtected($attackerScore, $defenderScore)) {
            return 'Ce clan est protégé de vos attaques : son score est trop éloigné du vôtre.';
        }

        return null;
    }
}
