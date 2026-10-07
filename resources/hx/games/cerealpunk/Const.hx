package cerealpunk;

// Const.mt
class Const {
	public static inline var WIDTH = 8;
	public static inline var HEIGHT = 12;

	public static inline var PIERRE_LIFE = 3;

	public static inline var DX = 45;
	public static inline var DY = -45;
	public static inline var YLIMIT = 65;

	public static var NLEGS:KKConst = KKApi.const(3);

	public static inline var BULLE = 20;
	public static inline var PIERRE = 21;

	public static inline var GOLD = 9;

	public static var C100:KKConst = KKApi.const(100);
	public static var C1000:KKConst = KKApi.const(1000);
	public static var C5000:KKConst = KKApi.const(5000);

	public static inline var BONUS1 = 22;
	public static inline var BONUS2 = 23;

	public static inline var PLAN_BG = 0;
	public static inline var PLAN_HERO = 1;
	public static inline var PLAN_LEGUME = 2;
	public static inline var PLAN_POP = 3;
	public static inline var PLAN_INTERF = 4;

	public static function setPercentColor(mc:MC, prc:Float, col:Int) {
		mc.setPercentColor(prc, col);
	}
}
