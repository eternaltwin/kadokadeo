<?php

namespace Tests\Unit;

use App\Models\Game;
use PHPUnit\Framework\TestCase;

class GameKeyTest extends TestCase
{
    public function test_game_key_and_class_name_drop_accents(): void
    {
        $game = new Game(['name' => 'Chakré Bouddha']);

        $this->assertSame('chakrebouddha', $game->game_key);
        $this->assertSame('GameChakreBouddha', $game->pascal_name);
    }

    public function test_game_key_and_class_name_of_plain_names(): void
    {
        $this->assertSame('opalus2', (new Game(['name' => 'Opalus 2']))->game_key);
        $this->assertSame('GameOpalus2', (new Game(['name' => 'Opalus 2']))->pascal_name);
        $this->assertSame('kslash', (new Game(['name' => 'K-Slash']))->game_key);
        $this->assertSame('GameKillBulle', (new Game(['name' => 'Kill Bulle']))->pascal_name);
    }
}
