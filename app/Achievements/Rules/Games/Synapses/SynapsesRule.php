<?php

namespace App\Achievements\Rules\Games\Synapses;

use App\Achievements\AchievementRule;
use App\Achievements\Events\GameRunCompleted;
use App\Enums\AchievementCategory;

abstract class SynapsesRule implements AchievementRule
{
    public function __construct(private readonly string $gameKey = 'synapses') {}

    public function category(): AchievementCategory
    {
        return AchievementCategory::GAME;
    }

    public function gameKey(): ?string
    {
        return $this->gameKey;
    }

    public function supports(object $event): bool
    {
        return $event instanceof GameRunCompleted && $event->gameKey() === $this->gameKey;
    }

    public function validate(GameRunCompleted $event): bool
    {
        $connectedNeurons = data_get($event->stats, 'cn', []);
        $levelStats = data_get($event->stats, 'ls', []);

        if (!is_array($connectedNeurons) || !is_array($levelStats) || count($connectedNeurons) !== count($levelStats)) {
            return false;
        }

        foreach ($connectedNeurons as $level => $levelConnectedNeurons) {
            if (!is_array($levelConnectedNeurons) || count($levelConnectedNeurons) > 80) {
                return false;
            }

            foreach ($levelConnectedNeurons as $neuronScore) {
                if (!is_int($neuronScore) || $neuronScore < 0) {
                    return false;
                }
            }

            $stats = $levelStats[$level] ?? null;
            if (!is_array($stats) || !array_key_exists('to', $stats) || !array_key_exists('es', $stats)) {
                return false;
            }

            if (!in_array($stats['to'], [0, 1], true) || !is_array($stats['es']) || count($stats['es']) < 1 || count($stats['es']) > 5) {
                return false;
            }

            foreach ($stats['es'] as $enemyScore) {
                if (!is_int($enemyScore) || $enemyScore < 0) {
                    return false;
                }
            }

            if ($stats['es'][0] !== count($levelConnectedNeurons)) {
                return false;
            }
        }

        return true;
    }

    protected function playerWinsLevel(array $scores): bool
    {
        return count($scores) > 0 && $scores[0] === max($scores);
    }
}
