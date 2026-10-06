package redraid;

import pixi.filters.colormatrix.ColorMatrixFilter;
import redraid.Units;

// Cs of the original, and the trigonometry of the gameplay rounded to 1e-9 (the same on every browser: replays)
class Cs {
	public static inline var mcw = 300;
	public static inline var mch = 300;

	public static var game:Game;

	public static inline var C1 = 1;
	public static inline var C15 = 15;
	public static inline var C250 = 250;
	public static inline var C500 = 500;
	public static inline var C1500 = 1500;
	public static inline var C2000 = 2000;
	public static inline var C5000 = 5000;

	public static var RENFORT_STATS:Array<Float>;

	public static inline var SELECT_TRESHOLD = 1.3;
	public static inline var DIF_RATE = 0.007;

	public static inline var GAME_MODE = 1; // 0:RENFORT 1:BONUS
	public static inline var SELECT_MODE = 1; // 0:CLASSIC 1:MIX 2:SEB
	public static inline var SPACE_MODE = 1; // 0:ALL 1:INVERSE

	public static function init() {
		Ally.sel = [];
		RENFORT_STATS = [1, 0.5, 0.4, 0.3, 0.2, 0.1, 0.05];
	}

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

	public static inline function mm(a:Float, b:Float, c:Float):Float {
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

	public static function getOutPos(ray:Float):{x:Float, y:Float} {
		var rnd = Seed.random(4);
		var w = mcw;
		var h = mch;
		switch (rnd) {
			case 0:
				return {x: -ray, y: Seed.rand() * h};
			case 1:
				return {x: w + ray, y: Seed.rand() * h};
			case 2:
				return {x: Seed.rand() * w, y: -ray};
			case 3:
				return {x: Seed.rand() * w, y: h + ray};
		}
		return null;
	}

	// Cs.setPercentColor: the clip mixed with a colour (prc %), a colour matrix filter of its own
	public static function setPercentColor(mc:ASprite, prc:Float, col:Int) {
		if (prc <= 0) {
			mc.filters = null;
			return;
		}
		var f:ColorMatrixFilter = mc.filters != null && mc.filters.length > 0 ? cast mc.filters[0] : null;
		if (f == null)
			f = new ColorMatrixFilter();
		// (the integer percentages of Color.setTransform)
		var m = Std.int(100 - prc) / 100;
		var c = prc / 100;
		f.matrix = [
			m, 0, 0, 0, Std.int(c * ((col >> 16) & 0xFF)) / 255,
			0, m, 0, 0, Std.int(c * ((col >> 8) & 0xFF)) / 255,
			0, 0, m, 0, Std.int(c * (col & 0xFF)) / 255,
			0, 0, 0, 1, 0
		];
		mc.filters = [f];
	}
}
