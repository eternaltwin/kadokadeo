package cyclopean;

class Cs {
	public static inline var mcw = 300;
	public static inline var mch = 300;

	public static inline var LEVEL_SIDE = 1600;
	public static inline var LEVEL_SIZE = 100;

	public static inline var MARGIN = 0;

	public static var SCORE_GREEN = KKApi.const(1000);
	public static var SCORE_BONUS = KKApi.aconst([1500, 4000, 8000]);
	public static var SPAWN = [
		0, 0, 0, 0, 0, // GREEN
		1, 1, // BLUE
		2, // PINK
		3, 3, 3, 3, // TIME
		4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 // BALL
	];

	public static inline var TIME_MAX = 3600;
	public static inline var BONUS_TIME = 1000;

	public static inline var SCORE_LAP = 2;
	public static var SCORE_BASE = KKApi.const(3);

	public static var game:Game;

	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	public static function sMod(v:Float, mod:Float):Float {
		while (v >= mod)
			v -= mod;
		while (v < 0)
			v += mod;
		return v;
	}

	public static function hMod(v:Float, mod:Float):Float {
		while (v > mod)
			v -= mod * 2;
		while (v < -mod)
			v += mod * 2;
		return v;
	}

	public static function getDist(o:{x:Float, y:Float}, o2:{x:Float, y:Float}):Float {
		var dx = o2.x - o.x;
		var dy = o2.y - o.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	// Flash's _rotation setter: modulo 360 (the sign of the dividend), then into -180..180; NaN is ignored by Flash
	// (the caller keeps the previous value, see Level.getRandomBase)
	public static function normRot(v:Float):Float {
		v = v % 360;
		if (v < -180)
			v += 360;
		else if (v > 180)
			v -= 360;
		return v;
	}

	// ---------------------------------------------------------------- port: deterministic maths
	// Math.cos / sin / atan2 / pow can differ in their last bits between browsers: every result that enters the game
	// state is rounded to 1/65536 (an exact binary fraction), so a replay plays the same everywhere
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	public static inline function cos(a:Float):Float {
		return q(Math.cos(a));
	}

	public static inline function sin(a:Float):Float {
		return q(Math.sin(a));
	}

	public static inline function atan2(y:Float, x:Float):Float {
		return q(Math.atan2(y, x));
	}

	public static inline function pow(a:Float, b:Float):Float {
		return q(Math.pow(a, b));
	}
}
