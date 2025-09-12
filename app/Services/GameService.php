<?php

namespace App\Services;

use App\Models\DailyGame;
use App\Models\Game;

class GameService
{
    public function __construct()
    {
    }

    public function getContract(Game $game)
    {
        $score = $this->generateScore($game->stars);
        $maxScore = intval(max($game->stars) * 1.05);
        $points = $this->getRewardPoints($score, $maxScore);

        return [$score, $points];
    }

    public function generateSeed(): string
    {
        return bin2hex(random_bytes(16)); // 32 characters long
    }

    public function getDailySeed(Game $game): string
    {
        $dailyGame = $game->dailyGames()->where('day', now()->today())->first();

        if (!$dailyGame) {
            throw new \Exception('No daily game for this game today');
        }

        return $dailyGame->seed;
    }

    public function getDailyGame(): ?DailyGame
    {
        return DailyGame::where('day', today())->first();
    }

    public function generateScore(array $thresholds): int
    {
        $peaks = [0.7, 0.2, 0.05];
        $thresholds = collect($thresholds)->sort();

        $ranges = [
            [1, $thresholds[0]],
            [$thresholds[0], $thresholds[1]],
            [$thresholds[1], $thresholds[2] * 1.05],
        ];

        // Choose which bell curve to use based on probabilities
        $rand = randomNumber();
        $cumulativeProb = 0;
        $selectedRange = 0;

        foreach ($peaks as $i => $peak) {
            $cumulativeProb += $peak;
            if ($rand <= $cumulativeProb) {
                $selectedRange = $i;
                break;
            }
        }

        // Generate a score within the selected range using a normal distribution
        [$rangeMin, $rangeMax] = $ranges[$selectedRange];
        $rangeCenter = ($rangeMin + $rangeMax) / 2;
        $rangeStd = ($rangeMax - $rangeMin) / 6; // Écart-type = 1/6 de la largeur

        // Generate the score using a normal distribution (Box-Muller approximation)
        $score = $this->generateNormalRandom($rangeCenter, $rangeStd);
        $score = max($rangeMin, min($rangeMax, $score));

        return intval(round($score));
    }

    /**
     * Generates points with progressive unlocking based on the targetScore
     * The higher the score, the more reward levels are unlocked
     */
    public function getRewardPoints(int $targetScore, int $maxScore): int
    {
        $r = $targetScore / $maxScore;

        // Base points & base probabilities
        $basePoints = [1, 10, 25, 50, 100, 500, 1000, 10000];
        $baseProba = [0, 0.5, 0.75, 0.88, 0.94, 0.97, 0.99, 1];

        // Progressive unlocking of levels based on r
        if ($r < 0.2) {
            $unlockLevel = 3; // Up to 50 points (index 3)
        } elseif ($r < 0.4) {
            $unlockLevel = 4; // Up to 100 points (index 4)
        } elseif ($r < 0.6) {
            $unlockLevel = 5; // Up to 500 points (index 5)
        } elseif ($r < 0.8) {
            $unlockLevel = 6; // Up to 1000 points (index 6)
        } else {
            $unlockLevel = 7; // Up to 10000 points (index 7)
        }

        // Take only unlocked levels
        $pointsValues = array_slice($basePoints, 0, $unlockLevel + 1);
        $probaPoints = array_slice($baseProba, 0, $unlockLevel + 1);

        // Adjust the last prob to make it 1.0 max
        $probaPoints[count($probaPoints) - 1] = 1.0;

        $rand = randomNumber();

        // For bad scores, lower the reward
        if ($r < 0.5) {
            $penalty = 0.3 + ($r / 2); // Factorr of 0.3 to 0.55
            $rand = $rand * $penalty;
        }

        // Linear interpolation in the unlocked range
        for ($i = 0; $i < count($probaPoints) - 1; $i++) {
            if ($probaPoints[$i] <= $rand && $rand <= $probaPoints[$i + 1]) {
                $ratio = ($rand - $probaPoints[$i]) / ($probaPoints[$i + 1] - $probaPoints[$i]);
                $points = $pointsValues[$i] + $ratio * ($pointsValues[$i + 1] - $pointsValues[$i]);
                return intval(round($points));
            }
        }

        // Fallback
        return $pointsValues[count($pointsValues) - 1];
    }

    /**
     * Generates a random number following a normal distribution
     * Uses the Box-Muller method
     */
    private function generateNormalRandom(float $mean, float $std): float
    {
        $u = randomNumber();
        $v = randomNumber();

        $mag = $std * sqrt(-2.0 * log($u));

        return $mag * sin(2.0 * pi() * $v) + $mean;
    }

}
