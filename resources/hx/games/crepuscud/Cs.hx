package crepuscud;

import mt.bumdum.Sprite;
import common_haxe_avm1.KKApi;

class Cs {
	public static var BRAY = 16;
	public static var NEW_GEN_SCALE = 3;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var FL_PERFECT = false;

	public static var RAY_MISSILE = 50 * NEW_GEN_SCALE;
	public static var RAY_PATRIOT = 78 * NEW_GEN_SCALE;
	public static var MISSILE_MAX = 24;
	public static var REPLENISH_CYCLE = 30;

	public static var PERFECT_RAY = Cs.S(5);

	public static var SCORE_MISSILE = KKApi.aconst([400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000]);
	public static var SCORE_BONUS = KKApi.aconst([1000, 3000, 8000]);

	public static inline function S(v:Float):Float {
		return v * NEW_GEN_SCALE;
	}

	public static inline function I(v:Int):Int {
		return v * NEW_GEN_SCALE;
	}
}
