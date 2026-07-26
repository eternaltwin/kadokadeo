package starfang;

import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;

class Cs {
	public static var mcw = KadoKadeoManager.I(300);
	public static var mch = KadoKadeoManager.I(300);

	public static var START_SAFE_DIST = KadoKadeoManager.I(40);
	public static var WEAPON_POWER_MAX = 4;

	// GAMEPLAY
	public static var DAMAGE_BOMB = 4;
	public static var DAMAGE_TENTACULE = 0.25;
	public static var DAMAGE_HOMING = 2.5;

	// SCORES
	public static var SCORE_ASTEROID = KKApi.aconst([50, 75, 150, 200, 300]);
	public static var C5 = KKApi.const(5);
	public static var C0 = KKApi.const(0);

	//
	public static var game:Game;

	public static inline function rand():Float {
		return Seed.rand();
	}

	public static inline function random(max:Int):Int {
		return Seed.random(max);
	}

	public static function init() {}
}
