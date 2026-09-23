package bactery;

import common_haxe_avm1.KKApi;

class Const {
	public static var PX = KadoKadeoManager.I(24);
	public static var PY = KadoKadeoManager.I(24);

	public static var WIDTH = 10;
	public static var HEIGHT = 10;
	public static var BSIZE = KadoKadeoManager.I(28);

	public static var C150 = KKApi.const(150);
	public static var C50 = KKApi.const(50);
	public static var C1000 = KKApi.const(1000);

	public static var PLAN_BG = 0;
	public static var PLAN_UNDER = 1;
	public static var PLAN_BLOCKS = 2;
	public static var PLAN_PART = 3;
	public static var PLAN_PANEL = 4;

	public static var ID_BONUS = 4;
	public static var ID_WALL = 9;
	public static var ID_MONSTER = 10;
}
