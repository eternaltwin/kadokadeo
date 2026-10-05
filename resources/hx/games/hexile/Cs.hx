package hexile;

class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var WW = 20.5;
	public static var HH = 18;

	public static var MX = 150;
	public static var MY = -26;

	public static var DIR = [[1, 0], [1, 1], [0, 1], [-1, 0], [-1, -1], [0, -1]];

	public static var SCORE_HEX = KKApi.aconst([600, 800, 400]);
	public static var SCORE_ALLY = KKApi.const(50);
	public static var SCORE_VICTORY = KKApi.const(3000);

	public static inline function getX(px:Int, py:Int):Float {
		return MX + (px - py) * WW * 1.5;
	}

	public static inline function getY(px:Int, py:Int):Float {
		return MY + (px + py) * HH;
	}

	// a power whose result decides the game, rounded to 1/65536 (Math.pow can differ in the last bits between
	// browsers, and the AI sorts its moves on it)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
