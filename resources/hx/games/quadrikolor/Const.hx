package quadrikolor;

// Const.mt
class Const {
	public static inline var NBALLS = 7;
	public static inline var BALL_RAY = 13;

	public static inline var MIN_SPEED = 1;
	public static inline var MAX_SPEED = 30;
	public static inline var FRICTION = 0.96;
	public static inline var SHIP_MASS = 1;
	public static inline var BALL_MASS = 1;
	public static inline var BOUNDS_COEF = 0.8;
	public static inline var EPSILON = 0.7;

	public static inline var SHIP_LIMIT = 45;
	public static inline var LIMIT = 65;

	public static var COLORS = [0xDD0000, 0xEEAA00, 0xDDEE22, 0x33DD22, 0x22AA88, 0x4488EE, 0xAA55DD];

	public static var C5000:KKConst = KKApi.const(5000);
	public static var POINTS:Array<KKConst> = KKApi.aconst([1000, 700, 500, 300, 200, 100, 50]);

	public static inline var MIN_Y = 14;
	public static inline var PLAN_LINE = 1;
	public static inline var PLAN_BALL = 2;
	public static inline var PLAN_INTERF = 5;

	public static inline var INIT_MIN_DIST = 30;
	public static inline var MAX_CARBU = 14;
	public static inline var INIT_CARBU = 7;

	public static inline var MIN_LINE = 500; // 300;
	public static inline var DELTA_LINE = 10;

	// port: the result of a transcendental function (pow, log, atan2, cos, sin) that enters the game state, rounded to
	// 2^-30 so that every browser gives the same replay (their last bits can differ); fine enough for the 1 / 100000
	// tolerance of Physics.collideBounds
	public static inline function q(v:Float):Float {
		return Math.round(v * 1073741824) / 1073741824;
	}
}
