package pioupiou;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var LVL_WIDTH:Int = 9;
	public static var LVL_HEIGHT:Int = 11;

	public static var BLK_WIDTH:Int = 30 * NEW_GEN_SCALE;
	public static var BLK_HEIGHT:Int = 30 * NEW_GEN_SCALE;

	public static var DELTA_X:Int = 15 * NEW_GEN_SCALE;
	public static var DELTA_Y:Int = 0 * NEW_GEN_SCALE;

	public static var PLAN_BG:Int = 0;
	public static var PLAN_FX:Int = 5;
	public static var PLAN_HERO:Int = 4;
	public static var PLAN_BONUS:Int = 3;
	public static var PLAN_BLOCK:Int = 2;

	public static var BLK_SPEED:Int = 3 * NEW_GEN_SCALE;
	public static var BONUS_PROBAS:Int = 100;

	public static var BONUS_PROBAS_TBL:Array<Int> = [50, 10, 1];
	public static var BONUS_POINTS = KKApi.aconst([200, 500, 3000]);
}
