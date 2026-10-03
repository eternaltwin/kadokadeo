package abcrevolution;

class Cs {
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

	public static inline function pow(a:Float, b:Float):Float {
		return qt(Math.pow(a, b));
	}
}
