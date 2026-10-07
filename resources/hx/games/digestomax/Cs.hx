package digestomax;

// Cs.hx of the original (constants of the grid: 9 x 8 cells of 32 px from (7, 0), the map scrolled down by 14 px)
class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var CS = 32;
	public static var MX = 7.0;
	public static var MY = 0.0;
	public static var XMAX = 9;
	public static var YMAX = 8;

	public static var COLOR_MAX = 4;
	public static var COMBO_LIMIT = 4;

	public static var SCORE_FRUIT = KKApi.const(150);
	public static var SCORE_PERFECT = KKApi.const(2500);

	public static var FRUIT_COLOR = [0xFF0000, 0x88FF00, 0xFF8800, 0x4400FF];

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var CDIR = [[1, 0], [0, 1]];

	// (port: the SWF was reloaded for every game; Cs.init and Game.levelUp change these statics)
	public static function reset() {
		MX = 7.0;
		MY = 0.0;
		COMBO_LIMIT = 4;
	}

	public static function init() {
		MX += CS * 0.5;
		MY += CS * 0.5;
	}

	public static inline function getPX(x:Float) {
		return Std.int((x - MX) / CS);
	}

	public static inline function getPY(y:Float) {
		return Std.int(((Cs.mch - y) - MY) / CS);
	}

	public static inline function getX(x:Float) {
		return MX + x * CS;
	}

	public static inline function getY(y:Float) {
		return MY + y * CS;
	}

	public static function isOut(px:Float, py:Float) {
		return px < 0 || px >= XMAX || py < 0 || py >= YMAX;
	}

	public static function getScore(n:Int):KKConst {
		return KKApi.cmult(SCORE_FRUIT, KKApi.const(2 * n - 2));
	}
}

// mt.bumdum.Lib.Num
class Num {
	public static inline function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}
}
