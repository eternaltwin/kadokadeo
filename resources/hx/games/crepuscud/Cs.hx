package crepuscud;

import common_haxe_avm1.KKApi;

class Cs {
	public static var BRAY = 16;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];
	public static var mcw = KadoKadeoManager.I(300);
	public static var mch = KadoKadeoManager.I(300);

	public static var FL_PERFECT = false;

	public static var RAY_MISSILE = KadoKadeoManager.I(50);
	public static var RAY_PATRIOT = KadoKadeoManager.I(78);
	public static var MISSILE_MAX = 24;
	public static var REPLENISH_CYCLE = 30;

	public static var PERFECT_RAY = KadoKadeoManager.S(5);

	public static var SCORE_MISSILE = KKApi.aconst([400, 600, 800, 1000, 1200, 1400, 1600, 1800, 2000]);
	public static var SCORE_BONUS = KKApi.aconst([1000, 3000, 8000]);
}
