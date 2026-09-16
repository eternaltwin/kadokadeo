package alchimie;

class Cs {
	public static var game:Game;

	public static var WIDTH = 6;
	public static var HEIGHT = 9;

	public static var COIN_SIZE = KadoKadeoManager.I(30);

	public static var ID_COUNT = 4;
	public static var EXPLODE_COUNT = 3;

	public static var POS_X = KadoKadeoManager.I(108);
	public static var POS_Y = COIN_SIZE;

	public static var POINTS = KKApi.aconst([1, 3, 10, 30, 100, 300, 1000, 3000, 10000, 20000, 40000, 80000]);

	public static var PLAN_BG = 0;
	public static var PLAN_INTERF = 0;
	public static var PLAN_COIN = 2;
	public static var PLAN_PART = 4;
}
