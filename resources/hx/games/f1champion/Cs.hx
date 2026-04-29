package f1champion;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var WIDTH = 300 * NEW_GEN_SCALE;
	public static var HEIGHT = 300 * NEW_GEN_SCALE;
	public static var MINSPEED = 10 * NEW_GEN_SCALE;

	public static var PLAN_BG = 0;
	public static var PLAN_TRAIL = 1;
	public static var PLAN_F1 = 2;
	public static var PLAN_OPTION = 2;
	public static var PLAN_PART = 3;
	public static var PLAN_INTERFACE = 4;

	public static var CAR_SCALE = 60;
	public static var SHADOW_X = 3 * NEW_GEN_SCALE;
	public static var SHADOW_Y = 4 * NEW_GEN_SCALE;
	public static var STEER_DELTA_MAX = 3.8;
	public static var STEER_INPUT_DRY = 0.19;
	public static var STEER_INPUT_OIL = 0.145;
	public static var STEER_FRICTION_DRY = 0.952;
	public static var STEER_FRICTION_OIL = 1.0035;

	public static var MAXLIFE = 100;

	public static var OPTIONS_PROBA = 100;

	public static var OPTIONS = [3, // life
		20, // score 1
		4, // score 2
		1, // score 3
		6, // oil
	];
}
