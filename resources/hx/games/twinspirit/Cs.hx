package twinspirit;

class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var CS = 30;
	public static var XMAX = 0;
	public static var YMAX = 0;

	public static var CLOUD_FADE_PRC = 25;
	public static var CLOUD_FADE_COLOR = 0xE6711A;

	public static var SCORE_ROBERT = 5000;

	public static var DIR = [[1, 0], [1, 1], [0, 1], [-1, 0], [-1, -1], [0, -1]];

	public static function init() {
		XMAX = Math.ceil(mcw / CS);
		YMAX = Math.ceil(mch / CS);
	}

	inline public static function getPX(x:Float) {
		return Std.int(x / CS);
	}

	inline public static function getPY(y:Float) {
		return Std.int(y / CS);
	}

	public static function getScore(bf:BadFamily):Int {
		return switch (bf) {
			case DRONE: 50;
			case KOBOLD: 100;
			case SUPER_DRONE: 100;
			case SENTINELLE: 250;
			case ZILA: 1500;
			case ASSASSIN: 500;
			case VOLT_BALL: 1500;
			case BEHEMOTH: 3000;
		}
	}

	public static function isOut(x:Float, y:Float, m:Float, ?my:Float) {
		// (my==0 in the original is a comparison: my stays null, NaN in the sum, the bottom test is always false)
		if (my == null)
			return x < m || x > mcw - m || y < m;
		return x < m || x > mcw - m || y < m || y > mch - (m + my);
	}

	// trigonometry of the gameplay rounded to 1e-9: the same on every browser (replays)
	public static inline function qt(v:Float):Float {
		return Math.round(v * 1e9) / 1e9;
	}

	public static inline function cos(a:Float):Float {
		return qt(Math.cos(a));
	}

	public static inline function sin(a:Float):Float {
		return qt(Math.sin(a));
	}

	public static inline function atan2(y:Float, x:Float):Float {
		return qt(Math.atan2(y, x));
	}
}
