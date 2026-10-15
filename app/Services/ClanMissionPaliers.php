<?php

namespace App\Services;

use App\Models\Game;
use App\Settings\ClanSettings;

// the scores to reach of the steps of a mission. The paliers of a game: half the first star, the first star, between the
// first and the second, the second... the last star, then beyond it a share of the way up to the "Score 1500" of the game
// (games.score_rankv1). A mission mixes them: its top palier goes up every `every` missions, a share of its steps is at
// the top palier (bigger with the paliers), a few steps stay easy (half the first star), the others are spread on the
// paliers under the top one. Used by ClanMissionService::generateMission and the preview of the admin.
final class ClanMissionPaliers
{
    public function __construct(
        public readonly int $every,
        public readonly float $hardShareMin,
        public readonly float $hardShareStep,
        public readonly float $hardShareMax,
        public readonly int $easySteps,
        public readonly int $spread,
        public readonly float $beyondLastStar,
    ) {}

    public static function fromSettings(ClanSettings $settings): self
    {
        return self::fromArray((array) $settings->toArray());
    }

    // the settings (the form of the admin while it is edited)
    public static function fromArray(array $values): self
    {
        return new self(
            every: max(1, (int) ($values['mission_paliers_every'] ?? 1)),
            hardShareMin: (float) ($values['mission_hard_share_min'] ?? 0),
            hardShareStep: (float) ($values['mission_hard_share_step'] ?? 0),
            hardShareMax: (float) ($values['mission_hard_share_max'] ?? 1),
            easySteps: max(0, (int) ($values['mission_easy_steps'] ?? 0)),
            spread: max(1, (int) ($values['mission_spread_paliers'] ?? 1)),
            beyondLastStar: max(0, (float) ($values['mission_beyond_last_star'] ?? 0)),
        );
    }

    // the paliers beyond the last star, when the game has a "Score 1500" above it
    public function beyondCount(): int
    {
        return $this->beyondLastStar > 0 ? (int) floor(1 / $this->beyondLastStar + 1e-9) : 0;
    }

    // the top palier of a mission (the paliers of 3 stars: 0 to 5, then beyond the last star)
    public function topPalier(int $number, int $starsCount = 3): int
    {
        return min(2 * $starsCount - 1 + $this->beyondCount(), intdiv(max(0, $number - 1), $this->every));
    }

    /**
     * The paliers of the steps of a mission, the easiest first (to shuffle).
     *
     * @return list<int>
     */
    public function levels(int $number, int $steps, int $starsCount = 3): array
    {
        if ($steps <= 0) {
            return [];
        }
        $top = $this->topPalier($number, $starsCount);
        $share = min($this->hardShareMax, $this->hardShareMin + $this->hardShareStep * $top);
        $hard = max(1, (int) round($steps * $share));
        $easy = min($steps - $hard, $this->easySteps);
        $rest = $steps - $hard - $easy;
        // the others, spread on the paliers under the top one (above the easy one)
        $from = max(min($top, 1), $top - $this->spread);
        $to = max($from, $top - 1);
        $middle = [];
        for ($i = 0; $i < $rest; $i++) {
            $middle[] = (int) round($from + ($to - $from) * ($rest > 1 ? $i / ($rest - 1) : .5));
        }

        return [...array_fill(0, $easy, 0), ...$middle, ...array_fill(0, $hard, $top)];
    }

    /**
     * The scores of the paliers of a game.
     *
     * @return list<float>
     */
    public function scores(array $stars, ?int $scoreRankV1): array
    {
        $stars = collect($stars)->map(fn ($star) => (float) $star)->sort()->values();
        $paliers = [];
        foreach ($stars as $index => $star) {
            $paliers[] = $index === 0 ? $star / 2 : ($stars[$index - 1] + $star) / 2;
            $paliers[] = $star;
        }
        $last = $stars->last();
        if ($last !== null && $scoreRankV1 !== null && $scoreRankV1 > $last) {
            for ($k = 1; $k <= $this->beyondCount(); $k++) {
                $paliers[] = $last + ($scoreRankV1 - $last) * min(1, $k * $this->beyondLastStar);
            }
        }

        return $paliers;
    }

    // the score to reach on a game at a palier (its highest one when it has fewer)
    public function targetScore(Game $game, int $palier): int
    {
        $scores = $this->scores($game->stars ?? [], $game->score_rankv1);

        return max(1, (int) round($scores[min($palier, count($scores) - 1)]));
    }

    // the palier in the preview of the admin (3 stars)
    public function label(int $palier): string
    {
        return match (true) {
            $palier === 0 => '½ verte',
            $palier === 1 => 'verte',
            $palier === 2 => 'verte-orange',
            $palier === 3 => 'orange',
            $palier === 4 => 'orange-rouge',
            $palier === 5 => 'rouge',
            default => 'rouge +'.round(min(1, ($palier - 5) * $this->beyondLastStar) * 100).' %',
        };
    }
}
