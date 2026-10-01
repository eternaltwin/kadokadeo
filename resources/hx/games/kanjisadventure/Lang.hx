package kanjisadventure;

class Lang {
	public static var TRADER = [
		"Que voulez-vous acheter ?",
		"Vous n'avez pas assez de pièces d'or...",
		"Vous n'avez pas assez de place...",
	];

	public static var ITEMS = [
		"",
		"OR 1",
		"OR 2",
		"OR 3",
		"",
		"Armure cuir",
		"Armure métal",
		"Couteau",
		"Katana",
		"Pomme",
		"Viande",
		"3x Shurikens",
		"10x Shuriken",
		"Sac-à-dos",
		"Potion",
		"Super potion",
		"Grappin pointu",
		"Talisman anti mort-vivant",
		"Amulette rubis",
		"Amulette emeraude",
		"Amulette saphire",
		"Crystal vert",
		"Crystal bleu",
		"Crystal rose",
		"Patte porte-bonheur",
		"Pr. Feu",
		"Pr. Glace",
		"Bombe en bois",
		"Oreiller moelleux",
		"Pr. Teleport.",
		"Pr. Chaos",
		"Capuche Ours",
		"Os magique",
		"Bracelet qui pique",
		"Zippo étoilé"
	];

	static public function take(id:Int) {
		Game.me.log("Vous rammassez : " + ITEMS[id]);
	}

	static public function getBadName(bid:Int):String {
		var names = [
			"cendrillo",
			"dragonnet",
			"fouineur",
			"squelette vengeur",
			"guerrier Katunba",
			"cyclope furieux",
			"cauchemort",
			"mage des Lumbs"
		];
		var n = names[bid];
		// the summoned bear and dog had no name in the original ("undefined")
		return n != null ? n : (bid == 20 ? "l'ours" : "le chien");
	}
}
