package kslash;

import common_haxe_avm1.KKApi;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var SIZE = 24 * NEW_GEN_SCALE;
	public static var PLAT_ECART = 4;

	public static inline var ST_NORMAL = 0;
	public static inline var ST_CLIMB = 1;
	public static inline var ST_FLY = 2;
	public static inline var ST_DEATH = 3;
	public static inline var ST_SHOOT = 4;

	public static inline var OPT_KATANA = 0;
	public static inline var OPT_FLAMES = 1;
	public static inline var OPT_SCROLL = 2;

	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var game:Game;

	public static var C0 = KKApi.const(0);
	public static var C10 = KKApi.const(10);
	public static var C30 = KKApi.const(30);
	public static var C50 = KKApi.const(50);
	public static var C100 = KKApi.const(100);
	public static var C120 = KKApi.const(120);
	public static var C200 = KKApi.const(200);
	public static var C300 = KKApi.const(300);
	public static var C1000 = KKApi.const(1000);
	public static var C5000 = KKApi.const(5000);
	public static var C8000 = KKApi.const(8000);

	public static inline function rand():Float {
		return Seed.rand();
	}

	public static inline function random(max:Int):Int {
		return Seed.random(max);
	}
}
