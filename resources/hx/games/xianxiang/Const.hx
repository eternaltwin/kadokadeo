package xianxiang;

import common_haxe_avm1.KKApi;

class Const {
	public static var LVL_WIDTH = 6;
	public static var LVL_HEIGHT = 7;

	public static var BASE_X = 23;
	public static var BASE_Y = 20;
	public static var CARD_WIDTH = 43;
	public static var CARD_HEIGHT = 34;

	public static var auto = 0;
	public static var PLAN_BG = auto++;
	public static var PLAN_CARD = auto++;
	public static var PLAN_PATH = auto++;
	public static var PLAN_MATCH = auto++;
	public static var PLAN_FX = auto++;

	public static var NTURNS = 1;

	public static var COLOR_ALPHA = 100;

	public static var POINTS_ENCODE = KKApi.aconst([1, 50, 300, 1000]);

	public static var COLORS = [
		{
			r: 100,
			g: 50,
			b: 0
		},
		{
			r: 0,
			g: 100,
			b: 0
		},
		{
			r: 0,
			g: 0,
			b: 100
		},
		{
			r: 75,
			g: 50,
			b: 100
		}
	];
}
