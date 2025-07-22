<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class GameSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $catAction = \App\Models\Category::firstOrCreate(['name' => 'Action']);
        $catPuzzle = \App\Models\Category::firstOrCreate(['name' => 'Réflexion']);

        $catAction->games()->createMany([
            ['name' => 'ABC Revolution'],
            ['name' => 'Alphabounce'],
            ['name' => 'Iron Chouquette'],
            ['name' => 'K-Slash !'],
            ['name' => 'Kanji'],
            ['name' => 'Ellon In The Dark'],
            ['name' => 'Interwheel'],
            ['name' => 'Piou-Piou'],
            ['name' => 'Manda'],
            ['name' => 'Schizo Fuzz'],
            ['name' => 'Mini-Race'],
            ['name' => 'Kavern'],
            ['name' => 'Twin Spirit'],
            ['name' => 'Judo Commando'],
            ['name' => 'Tianan Man'],
            ['name' => 'ZipZap'],
            ['name' => 'Kill Bulle'],
            ['name' => 'Starfang'],
            ['name' => 'Oursouinvader'],
            ['name' => 'Cyclopean'],
            ['name' => 'Punch-In !'],
            ['name' => 'Crepuscud'],
            ['name' => "Kanji's Nightmare"],
            ['name' => 'Chakré Bouddha'],
            ['name' => 'F1 Champion'],
            ['name' => 'Tout-Caen'],
            ['name' => 'El Tortuga nemesis'],
            ['name' => 'K-Train'],
            ['name' => 'Cosmo Crash'],
            ['name' => 'Magmax'],
            ['name' => 'Red Raid'],
            ['name' => 'Pioutch'],
            ['name' => 'Safari'],
            ['name' => 'Pacifik'],
            ['name' => 'Phagocytoz'],
            ['name' => 'Linea'],
            ['name' => 'Kanji Gaiden'],
            ['name' => 'Julianus'],
            ['name' => 'Popcorn'],
            ['name' => 'Happy Pti Tank'],
            ['name' => 'Brutal Teenage Crisis'],
            ['name' => 'Fafi 360'],
            ['name' => "Charlotte's Quest"],
            ['name' => 'Capman'],
            ['name' => 'Pulsar'],
            ['name' => 'Mel'],
            ['name' => 'Overdrive'],
            ['name' => 'Green Witch'],
        ]);

        $catPuzzle->games()->createMany([
            ['name' => 'Opalus Factory'],
            ['name' => 'Flushee'],
            ['name' => 'Opalus'],
            ['name' => 'Kaskade 2'],
            ['name' => 'Cooking Lili'],
            ['name' => 'Xian-Xiang'],
            ['name' => 'Aqua Splash'],
            ['name' => 'Atlanteine'],
            ['name' => "Logic'O"],
            ['name' => 'Choco-Mouche'],
            ['name' => 'Alchimie'],
            ['name' => 'Bactery'],
            ['name' => 'Binary'],
            ['name' => 'QuadriKolor'],
            ['name' => 'Hexile'],
            ['name' => "Kanji's Adventure"],
            ['name' => 'Razor'],
            ['name' => 'Spiroule'],
            ['name' => 'Cereal Punk'],
            ['name' => 'Travoltax'],
            ['name' => 'Synapses'],
            ['name' => 'Paradice'],
            ['name' => 'Invasion'],
            ['name' => 'Electrolink'],
            ['name' => 'Toy Maniak'],
            ['name' => 'Drakhan'],
            ['name' => 'Digestomax'],
            ['name' => 'Puzzle-Manda'],
            ['name' => 'Autrement'],
            ['name' => 'Hypercube'],
            ['name' => 'Klinker Surprise'],
            ['name' => 'Rock Faller'],
            ['name' => 'Animoz'],
            ['name' => 'Nosushi'],
            ['name' => 'BattleSheep'],
            ['name' => 'Trigo'],
            ['name' => 'IceWay'],
            ['name' => 'BadaBloom'],
            ['name' => 'Cataclismo'],
        ]);
    }
}
