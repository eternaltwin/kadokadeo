package logico;

// the helpers of mt.bumdum.Lib the original uses, as compiled in the released game.swf
class Num {
	// (null on a bad modulo, as compiled)
	public static function sMod(n:Float, mod:Float):Null<Float> {
		if (mod == 0 || Math.isNaN(mod) || Math.isNaN(n))
			return null;
		while (n >= mod)
			n -= mod;
		while (n < 0)
			n += mod;
		return n;
	}

	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	// Math.cos / sin / pow can differ in their last bits from a browser to another: the results that enter the game
	// are rounded to 1/65536 (an exact binary fraction), the same everywhere (replays)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
