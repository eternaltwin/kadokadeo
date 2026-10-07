package oursouinvader;

// Cs.mt of the original
class Cs {
	public static var mcw = 300;
	public static var mch = 300;
	public static var SEC = 32;
	public static var MARGE = 20;
	public static var SCORE_FROG = KKApi.const(1500);

	// SCORES
	public static var SCORE_CRABE = KKApi.const(250);
	public static var SCORE_OCTO = KKApi.const(400);
	public static var SCORE_BOMBER = KKApi.const(600);
	public static var SCORE_OYSTER = KKApi.const(800);
	public static var SCORE_BOSS = KKApi.const(4000);

	public static var SCORE_BONUS = KKApi.aconst([1000, 3000, 8000]);

	public static var game:Game;

	public static function init() {}

	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	// Color.setTransform({ra: int(100 - prc), rb: int(prc / 100 * r), ..., aa: 100, ab: 0}) (see MC.setPercentColor)
	public static function setPercentColor(mc:MC, prc:Float, col:Int) {
		mc.setPercentColor(prc, col);
	}

	// gameplay values computed with trigonometry or powers are rounded (1/65536 px, an exact binary fraction): the
	// replays stay identical on every browser even if their Math functions differ in the last bits
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
