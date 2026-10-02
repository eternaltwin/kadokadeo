package linea;

// Common.hx of the original: the constants of the game. Several of them change during a game (speeds, difficulty,
// the colours of the lines left): the Flash game was reloaded for every game, here Const.reset() starts each one
class Const {
	public static var inc = 0;
	public static var DP_BG = ++inc;
	public static var DP_BMP = ++inc;
	public static var DP_UNDER = ++inc;
	public static var DP_OBJECTS = ++inc;
	public static var DP_PERLIN = ++inc;
	public static var DP_BONUS = ++inc;
	public static var DP_DOT = ++inc;
	public static var DP_UI = ++inc;

	public static var FRAME_RATE = 40;
	public static var MARGIN = 22;
	public static var XMARGIN = 10;

	public static var LINE_BONUS:Int;
	public static var BASE_SCORE:Int;
	public static var ADDDECSPEED:Int;
	public static var ADDSPEED:Int;
	public static var SPEED:Int;
	public static var BASESPEED:Int;
	public static var VSCROLL:Int;
	public static var BACKSPEED:Int;
	public static var MINSPEED:Int;
	public static var CAMPER = 300;
	public static var DIF:Int;
	public static var ADDDIF:Int;
	public static var BONUS_COMBO:Int;

	public static var BONUS_GLOW = 20;

	public static var BASE_DOT_UP_SPEED:Int;
	public static var BASE_DOT_DOWN_SPEED:Int;
	public static var BASE_DOT_LEFT_SPEED:Int;
	public static var BASE_DOT_RIGHT_SPEED:Int;

	public static var DOT_X_SPEED:Int;
	public static var DOT_Y_SPEED:Int;
	public static var WIDTH = 600;
	public static var HEIGHT = 300;
	public static var START = 50;
	public static var DOT_START_POS = 150;
	public static var MAINCYCLE:Int;

	public static var OCYCLE:Int;
	public static var MINADD:Int;
	public static var MAXADD:Int;

	public static var BONUSX2_THRESHOLD:Int;
	public static var BONUSX2:Int;
	public static var BONUSX3_THRESHOLD:Int;
	public static var BONUSX3:Int;
	public static var BONUSX4_THRESHOLD:Int;
	public static var BONUSX4:Int;
	public static var KEYPRESSED:Int;

	public static var DOTCOLORS:Array<Array<Int>>;
	public static var OBJECTS_COLOR:Array<Array<Int>>;

	public static function reset() {
		LINE_BONUS = KKApi.const(5);
		BASE_SCORE = KKApi.const(2000);
		ADDDECSPEED = KKApi.const(1);
		ADDSPEED = KKApi.const(1);
		SPEED = KKApi.const(50);
		BASESPEED = KKApi.const(40);
		VSCROLL = KKApi.const(1);
		BACKSPEED = KKApi.const(5);
		MINSPEED = KKApi.const(KKApi.val(BASESPEED) - 20);
		DIF = KKApi.const(1);
		ADDDIF = KKApi.const(1);
		BONUS_COMBO = KKApi.const(12000);

		BASE_DOT_UP_SPEED = KKApi.const(-30);
		BASE_DOT_DOWN_SPEED = KKApi.const(30);
		BASE_DOT_LEFT_SPEED = KKApi.const(-20);
		BASE_DOT_RIGHT_SPEED = KKApi.const(20);

		DOT_X_SPEED = 2;
		DOT_Y_SPEED = 0;
		MAINCYCLE = KKApi.const(800);

		OCYCLE = KKApi.const(10);
		MINADD = KKApi.const(250);
		MAXADD = KKApi.const(50);

		BONUSX2_THRESHOLD = KKApi.const(100);
		BONUSX2 = KKApi.const(2);
		BONUSX3_THRESHOLD = KKApi.const(175);
		BONUSX3 = KKApi.const(3);
		BONUSX4_THRESHOLD = KKApi.const(250);
		BONUSX4 = KKApi.const(8);
		KEYPRESSED = KKApi.const(8);

		DOTCOLORS = [
			[Col.rgb2Hex(125, 198, 34), Col.rgb2Hex(0, 170, 189), Col.rgb2Hex(243, 194, 0), Col.rgb2Hex(226, 0, 120)],
			[Col.rgb2Hex(245, 211, 0), Col.rgb2Hex(44, 180, 49), Col.rgb2Hex(150, 129, 183), Col.rgb2Hex(207, 2, 38)],
			[Col.rgb2Hex(191, 177, 211), Col.rgb2Hex(187, 219, 136), Col.rgb2Hex(249, 244, 0), Col.rgb2Hex(191, 2, 34)],
			[Col.rgb2Hex(187, 219, 136), Col.rgb2Hex(245, 211, 0), Col.rgb2Hex(241, 175, 0), Col.rgb2Hex(207, 2, 38)],
			[Col.rgb2Hex(0, 177, 174), Col.rgb2Hex(94, 189, 71), Col.rgb2Hex(212, 85, 33), Col.rgb2Hex(254, 248, 134)],
			[Col.rgb2Hex(112, 199, 212), Col.rgb2Hex(255, 213, 114), Col.rgb2Hex(250, 114, 54), Col.rgb2Hex(205, 208, 10)],
			[Col.rgb2Hex(220, 151, 161), Col.rgb2Hex(197, 107, 35), Col.rgb2Hex(161, 17, 53), Col.rgb2Hex(163, 47, 117)],
		];
		OBJECTS_COLOR = [for (c in DOTCOLORS) c.concat([0xFFFFFF])];
	}
}
