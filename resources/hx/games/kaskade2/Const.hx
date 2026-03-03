package kaskade2;

import common_haxe_avm1.KKApi;

class Const {
	public static var MAXCOLORS = 6;

	public static var WIDTH = 300;
	public static var HEIGHT = 300;
	public static var BILLE_RAY = 26.5;

	public static var LVL_WIDTH = 8;
	public static var LVL_HEIGHT = 8;

	public static var PLAN_BG = 0;
	public static var PLAN_BILLE = 1;
	public static var PLAN_PART = 2;
	public static var PLAN_OVER = 3;

	public static var DELTA_X = WIDTH / 2;
	public static var DELTA_Y = HEIGHT / 2 + 18.5;

	public static var C100 = KKApi.const(100);
	public static var NCOUPS = KKApi.const(20);
}
