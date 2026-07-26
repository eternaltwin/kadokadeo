package f1champion;

class Cs {
	public static var WIDTH = KadoKadeoManager.I(300);
	public static var HEIGHT = KadoKadeoManager.I(300);
	public static var MINSPEED = KadoKadeoManager.I(10);

	public static var PLAN_BG = 0;
	public static var PLAN_TRAIL = 1;
	public static var PLAN_F1 = 2;
	public static var PLAN_OPTION = 2;
	public static var PLAN_PART = 3;
	public static var PLAN_INTERFACE = 4;

	public static var CAR_SCALE = 60;
	public static var SHADOW_X = KadoKadeoManager.I(3);
	public static var SHADOW_Y = KadoKadeoManager.I(4);
	public static var STEER_DELTA_MAX = 4.0;
	public static var STEER_INPUT_DRY = 0.2;
	public static var STEER_INPUT_OIL = 0.15;
	public static var STEER_FRICTION_DRY = 0.95;
	public static var STEER_FRICTION_OIL = 1.005;

	public static var MAXLIFE = 100;

	public static var OPTIONS_PROBA = 100;

	public static var OPTIONS = [3, // life
		20, // score 1
		4, // score 2
		1, // score 3
		6, // oil
	];
}
