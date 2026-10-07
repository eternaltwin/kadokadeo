package julianus;

class Const {
	public static inline var PLAN_BG = 0;
	public static inline var PLAN_BULLE = 2;
	public static inline var PLAN_HERO = 2;
	public static inline var PLAN_PIC = 1;
	public static inline var PLAN_PART = 3;

	public static inline var MAXY = 320;

	public static var SCORES = KKApi.aconst([200, 500, 1000]);

	// Math.pow(x, Timer.tmod) of the original with tmod = 0.8 (see Game.TMOD), written as numbers: the same in
	// every browser (Math.pow may differ in the last bit from one engine to another)
	public static inline var POW_070 = 0.7517586466500454; // 0.7 ^ 0.8
	public static inline var POW_080 = 0.8365116420730185; // 0.8 ^ 0.8
	public static inline var POW_090 = 0.9191661188401216; // 0.9 ^ 0.8
	public static inline var POW_095 = 0.9597958863520393; // 0.95 ^ 0.8
	public static inline var POW_097 = 0.9759271214644056; // 0.97 ^ 0.8
	public static inline var POW_098 = 0.9839677411474429; // 0.98 ^ 0.8

	// trigonometry (and powers) that enter the game state, rounded to 1/65536 (an exact binary fraction):
	// Math.cos / sin / atan2 / pow can differ in the last bits between browsers, and the replay must not
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}
