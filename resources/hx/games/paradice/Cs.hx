package paradice;

// Cs.mt of the original
class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var XMAX = 10;
	public static var YMAX = 10;

	public static var LIMIT_GAMEOVER = 9;

	public static var SQ = 24;
	public static var MD = 230;
	public static var ML:Float = 0;

	public static var PLAY_LEVEL = 282;
	public static var FILL_LEVEL = 320;

	// GAMEPLAY
	public static var COMBO_SIZE = 4;
	public static var PLAY_TIMER = 180;

	// RYTHM
	public static var DESTROY_TIMER = 12;
	public static var GROUND_CONTROL_SPEED = 0.22;

	// PARAMS
	// (the column timers of the original are a debug option, off: not ported)
	public static var FL_DISPLAY_TIMER = false;

	public static var C0 = KKApi.const(0);

	public static var game:Game;

	public static function init() {
		ML = (Cs.mcw - (Cs.SQ * Cs.XMAX)) * 0.5;
	}

	public static function setPercentColor(mc:MC, prc:Float, col:Int) {
		mc.setPercentColor(prc, col);
	}

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

	// gameplay values computed with trigonometry or powers are rounded (1/65536 px, an exact binary fraction): the
	// replays stay identical on every browser even if their Math functions differ in the last bits
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
