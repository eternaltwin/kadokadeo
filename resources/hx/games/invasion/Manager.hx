package invasion;

import common_haxe_avm1.KKApi;

class Manager {
	public static var root_mc:ASprite;
	public static var mode:{main:Void->Void};

	public static function init(mc) {
		if (!KKApi.available())
			return;
		root_mc = mc;
		mode = new Game(root_mc);
	}

	public static function main() {
		mt.Timer.update();
		mode.main();
	}
}
