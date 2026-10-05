package tubulo;

import common_haxe_avm1.KKApi;

class Cs {
	public static var BW = Cs.I(21);
	public static var BH = Cs.I(10);

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var mcw = Cs.I(300);
	public static var mch = Cs.I(300);

	public static var SCORE_TUBE = KKApi.aconst([50, -50, 0]);
	public static var SCORE_START = KKApi.const(2500);
	public static var SCORE_LEVEL = KKApi.const(1000);

	// public static var SCORE_GREEN = KKApi.const(50);
	// public static var SCORE_GREEN = KKApi.const(50);
	public static var SIDE = 7;

	// GAMEPLAY
	public static var COL_MAX = 3;
	public static var TUBE_SPEED = 0.175;

	public static var CHRONO_MAX = 1500 * 2;
	public static var CHRONO_BONUS = 250 * 2;

	// GFX
	// TOOLS
	public static function init() {}

	public static function getX(px:Float, py:Float) {
		return Cs.S(150) + (px - py) * BW;
	}

	public static function getY(px:Float, py:Float) {
		return Cs.S(125) + (px + py) * BH;
	}

	public static function S(value:Float) {
		return KadoKadeoManager.S(value);
	}

	public static function I(value:Int) {
		return KadoKadeoManager.I(value);
	}
}
