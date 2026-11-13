package kanjisadventure;

// The texts of the game
@:build(kado.I18nMacro.build("games/kanjisadventure"))
class Lang {
	// the monsters with a name; the summoned bear and dog had none in the original ("undefined")
	static inline var NAMED_MONSTERS = 8;
	static inline var BEAR = 20;

	static public function item(id:Int):String {
		return Lang.resolve('item_' + id);
	}

	static public function take(id:Int) {
		Game.me.log(Lang.take_item({item: item(id)}));
	}

	static public function monsterName(bid:Int):String {
		if (bid >= 0 && bid < NAMED_MONSTERS)
			return Lang.resolve('monster_' + bid);
		return bid == BEAR ? Lang.monster_bear : Lang.monster_dog;
	}
}
