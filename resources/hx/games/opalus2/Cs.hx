package opalus2;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var SIZE = 20 * NEW_GEN_SCALE;
	public static var GRID_MAX = 15;

	public static var DIR = [[0, 1], [1, 0], [0, -1], [-1, 0]];
	// public static var PROB = [ 10, 10, 10, 10, 10, 10, 0, 3, 2, 1 ]
	public static var PROB = [10, 10, 10, 10, 10, 10, 10];
	public static var SCORE_FALL = KKApi.const(2500);
	public static var SCORE_BALL = KKApi.const(750);
	public static var SCORE_BONUS = KKApi.const(125);
	public static var PROB_SUM = 0;

	public static var TIME_EXPLODE = 6;
	public static var TIME_FALL = 10;
	public static var TURN = KKApi.const(9);
	public static var DEC_TURN = KKApi.const(-1);

	// GAMEPLAY
	// SCORE
	public static var C1000 = KKApi.const(1000);

	public static var game:Game;
	static var DEFAULT_PROB:Array<Int> = [10, 10, 10, 10, 10, 10, 10];

	public static function init() {
		PROB_SUM = 0;
		for (s in PROB)
			PROB_SUM += s;
		// SCORE = KKApi.aconst([ 100, 100, 100, 100, 100, 100, 500, 1000, 5000 ])
	}

	public static function reset():Void {
		game = null;
		PROB = DEFAULT_PROB.copy();
		PROB_SUM = 0;
	}
}
