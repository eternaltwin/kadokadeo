package kavern;

import common_haxe_avm1.KKApi;

class Cs {
	public static var WIDTH = 10;
	public static var HEIGHT = 10;
	public static var BLOCK_SIZE = KadoKadeoManager.I(30);

	public static var LEGUMES_POINTS = KKApi.aconst([200, 500, 700, 1000, 1200, 1500]);
	public static var BONUS_PROBAS = [20, 1, 600];

	public static var PLAN_BG = 0;
	public static var PLAN_TERRE = 0;
	public static var PLAN_BLOCKS = 2;
	public static var PLAN_HERO = 2;
	public static var PLAN_BONUS = 3;
	public static var PLAN_PART = 4;
	public static var PLAN_INTERF = 5;

	public static var LIFE = KKApi.aconst([50, 20, 60, 100, 0]);
}
