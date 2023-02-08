<?php declare(strict_types=1);

namespace Kadokadeo\Games;

final class Games {
    /**
     * Get the list of all the games.
     */
    final public static function getAll(): array {
        return ["Mel", "Snake", "Iron Chouquette"];
    }
}
