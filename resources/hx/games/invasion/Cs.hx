package invasion;

import common_haxe_avm1.KKApi;

class Cs {
	public static var WIDTH = 7;
	public static var HEIGHT = 7;
	public static var BORDERSIZE = S(12);
	public static var SIZE = S(40);
	public static var DX = S(10);
	public static var DY = S(10);
	public static var mcw = S(300);
	public static var mch = S(300);

	public static var PLAN_BG = 0;
	public static var PLAN_CASES = 0;
	public static var PLAN_PERSO = 1;
	public static var PLAN_CURSOR = 3;
	public static var PLAN_FX = 2;

	public static inline var SATT = 0;
	public static inline var SDEF = 1;
	public static inline var SNOATT = 2;
	public static inline var SNODEF = 3;
	public static inline var SMARK = 4;
	public static inline var SDEF_FIRST = 5;

	public static var PROBAS_MONSTERS = [20, 5, 1];

	public static var HERO_DEATH_POINTS = KKApi.const(0);
	public static var HERO_KEEP_POINTS = KKApi.const(50);
	public static var MONSTER_POINTS = KKApi.aconst([200, 500, 1000]);
	public static var MONSTER_KEEP_POINTS = KKApi.aconst([0, 0, 0]);
	public static var GROUP_BONUS = KKApi.const(150);

	public static function pos(mc:ASprite, x:Int, y:Int) {
		mc._x = x * SIZE + DX;
		mc._y = y * SIZE + DY;
	}

	public static inline function S(v:Float):Float {
		return KadoKadeoManager.S(v);
	}

	public static inline function I(v:Int):Int {
		return KadoKadeoManager.I(v);
	}
}
