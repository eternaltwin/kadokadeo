package magmax;

// Const.mt of the original
class Const {
	public static var PLAN_BG = 0;
	public static var PLAN_HERO = 1;
	public static var PLAN_MONSTER = 1;
	public static var PLAN_TIR = 1;
	public static var PLAN_PART = 1;
	public static var PLAN_BONUS = 1;

	public static var BONUS = [500, 100, 10, 30, 3];
	public static var BONUS_POINTS = KKApi.aconst([200, 500, 3000]);
	public static var MONSTER_POINTS = KKApi.aconst([10, 30, 50]);
	public static var COMBOS = KKApi.aconst([100, 200, 300, 400]);

	// Tools.randomProbas of the original: an index drawn with the given weights
	public static function randomProbas(a:Array<Int>):Int {
		var n = 0;
		var i = a.length - 1;
		while (i >= 0)
			n += a[i--];
		n = Seed.random(n);
		i = 0;
		while (n >= a[i])
			n -= a[i++];
		return i;
	}

	// gameplay values computed with trigonometry or powers are rounded (1/65536 px, an exact binary fraction): the
	// replays stay identical on every browser even if their Math functions differ in the last bits
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
