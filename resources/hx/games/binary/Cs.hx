package binary;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;

	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var CS = 40 * NEW_GEN_SCALE;
	public static var MX = 50.0 * NEW_GEN_SCALE;
	public static var MY = 50.0 * NEW_GEN_SCALE;
	public static var XMAX = 5; // 6;
	public static var YMAX = 5; // 8;

	public static var COLOR_MAX = 4;
	public static var COMBO_LIMIT = 4;

	public static var DIR = [[0, 1], [1, 0], [-1, 0], [0, -1]];
	public static var CDIR = [[1, 0], [0, 1]];

	public static var SCORE_BALL = KKApi.aconst([100, 100, 100, 100, 150, 200, 300, 400, 500, 600, 800, 1000]);

	public static var COLOR_LIST = [
		0xFF0000, 0x00CC00, 0x5555FF, 0xCC8800, 0xCCCC00, 0xFF00FF, 0x8800FF, 0x00BBBB, 0x448800, 0x882200
	];

	public static function init() {
		COLOR_MAX = 4;
		COMBO_LIMIT = 4;
		MX = 50.0 * NEW_GEN_SCALE;
		MY = 50.0 * NEW_GEN_SCALE;
		MX += CS * 0.5;
		MY += CS * 0.5;
	}

	inline public static function getPX(x:Float) {
		return Std.int((x - MX) / CS);
	}

	inline public static function getPY(y:Float) {
		return Std.int(((Cs.mch - y) - MY) / CS);
	}

	inline public static function getX(x:Float) {
		return MX + x * CS;
	}

	inline public static function getY(y:Float) {
		return Cs.mch - (MY + y * CS);
	}
}
