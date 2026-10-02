package drakhan;

import common_haxe_avm1.KKApi;

class Cs {
	public static var RAY = KadoKadeoManager.I(12);
	public static var WW:Float;
	public static var HH:Float;

	public static var mcw = KadoKadeoManager.I(300);
	public static var mch = KadoKadeoManager.I(300);

	public static var GRID_RAY = 20;
	public static var WHEEL_RAY = KadoKadeoManager.I(132);
	public static var LAUNCH_RAY = KadoKadeoManager.I(160);

	public static inline var STEP_CONTROL = 1;
	public static inline var STEP_FLY = 2;
	public static inline var STEP_BLAST = 3;
	public static inline var STEP_FALL = 4;
	public static inline var STEP_SPAWN_CENTER = 5;
	public static inline var STEP_DEATH = 6;

	public static var DIR = [[0, 1], [1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1]];

	public static var COMBO_LIMIT = 3;
	public static var COLOR_START = 3;
	public static var COLOR_RYTHM = [10, 40, 70, 110, 200];

	public static var ICE_TURN_MIN = 10;
	public static var ICE_PROGRESSION = 400;
	public static var ICE_MIN = 0.1;
	public static var ICE_MAX = 0.3;

	public static var MU_TURN_MIN = 50;
	public static var MU_PROGRESSION = 400;
	public static var MU_MIN = 0;
	public static var MU_MAX = 1;

	public static var C1000 = KKApi.const(1000);
	public static var C2000 = KKApi.const(2000);
	public static var SCORE_COMBO_BASE = KKApi.const(200);
	public static var SCORE_COMBO_BONUS = KKApi.const(100);
	public static var SCORE_STAR = KKApi.aconst([50, 50, 50, 75, 100, 150, 250, 500]);

	public static var game:Game;

	public static function init():Void {
		WW = RAY * 2.25;
		HH = RAY * 1.25;
	}

	public static function getPos(x:Float, y:Float):{x:Int, y:Int} {
		var px = Math.round((y / HH + x / WW) / 2);
		var py = Math.round(x / WW - px);
		return {x: px, y: py};
	}
}
