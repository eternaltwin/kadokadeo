package cosmocrash;

// Cs.hx of the original
class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var lw = 2000;
	public static var lh = 450;

	public static var PMAX = 40;
	public static var PW = 40;
	public static var EC = 8;

	public static var CS = 30;
	public static var XMAX = 0;
	public static var YMAX = 0;

	// GAMEPLAY
	public static var LAND_SPEED_LIMIT = 1.5;
	public static var SHUTTLE_CAPACITY = 3;
	public static var BONUS_RARITY = 5;
	public static var SCORE_SHUTTLE = KKApi.const(1500);
	public static var SCORE_FOLK = KKApi.aconst([200, 400, 800, 1200]);
	public static var SCORE_BOARD = KKApi.const(50);
	public static var SCORE_BOARD_BONUS = KKApi.const(10);
	public static var SCORE_LOOP = KKApi.const(250);
	public static var SCORE_PERFECT = KKApi.const(50);

	//
	public static var CONTROL_TYPE = 1;

	public static function init() {
		PMAX = Std.int(lw / PW);
		XMAX = Math.ceil(lw / CS);
		YMAX = Math.ceil(lh / CS);
	}

	public static inline function getPX(x:Float):Int {
		return Std.int(x / CS);
	}

	public static inline function getPY(y:Float):Int {
		return Std.int(y / CS);
	}

	// ---------------------------------------------------------------- port
	// Math.cos, sin, atan2, pow of the gameplay rounded (they may differ in the last bits between browsers): a replay
	// must give the same flight everywhere
	public static inline function q(v:Float):Float {
		return Math.round(v * 4294967296.0) / 4294967296.0;
	}

	// Col.setPercentColor of the original (mt.bumdum.Lib): Color.setTransform with multipliers Std.int(100 - prc) % and
	// offsets Std.int(prc / 100 * channel)
	public static function setPercentColor(mc:MC, prc:Float, col:Int) {
		if (mc == null || mc.removed)
			return;
		var c = prc / 100;
		var m = Std.int(100 - prc) / 100;
		var mm = Math.round(Math.max(0, Math.min(1, m)) * 255);
		var r = Std.int(c * ((col >> 16) & 0xFF));
		var g = Std.int(c * ((col >> 8) & 0xFF));
		var b = Std.int(c * (col & 0xFF));
		inline function cl(v:Int)
			return v < 0 ? 0 : v > 255 ? 255 : v;
		mc.clip.setColour((mm << 16) | (mm << 8) | mm, (cl(r) << 16) | (cl(g) << 8) | cl(b));
	}
}

// mt.bumdum.Lib.Num of the original
class Num {
	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	public static function sMod(n:Float, mod:Float):Float {
		while (n >= mod)
			n -= mod;
		while (n < 0)
			n += mod;
		return n;
	}

	public static function hMod(n:Float, mod:Float):Float {
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}
}
