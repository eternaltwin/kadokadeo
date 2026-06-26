package flushee;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;

	public static var LVL_WIDTH = 6;
	public static var LVL_HEIGHT = 7;

	public static var PLAN_GEM = 1;

	public static var C1000 = KKApi.const(1000);
	public static var CMULT = KKApi.const(50);

	public static var PLAN_INTERF = 19;
	public static var PLAN_PART_SHADE = 20;
	public static var PLAN_PART = 21;

	public static var NEXPLS = 4;
	public static var NTOKENS = KKApi.const(10);

	public static var MINUS_ONE = KKApi.const(-1);
	public static var SMALL_BONUS = KKApi.const(1);
	public static var BIG_BONUS = KKApi.const(5);

	public static var NGEMS = 4;
	public static var ID_BONUS = NGEMS;
	public static var ID_TOKENS = NGEMS + 1;

	public static var CELL_SIZE = 36 * NEW_GEN_SCALE;
	public static var POSX = (6 + 36) * NEW_GEN_SCALE;

	public static var POSY = (-15 + 36) * NEW_GEN_SCALE;
	public static var YFALAISE = 275 * NEW_GEN_SCALE;
}
