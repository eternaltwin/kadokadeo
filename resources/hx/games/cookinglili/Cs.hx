package cookinglili;

import common_haxe_avm1.KKApi;

class Cs {
	static public var uniq = 0;

	static public var auto = 0;
	static public var DP_BG = auto++;
	static public var DP_PLASMA = auto++;
	static public var DP_GIRL = auto++;
	static public var DP_TOKENS = auto++;
	static public var DP_FX = auto++;
	static public var DP_INTERF = auto++;

	static public var SECOND = 32;

	static public var GWID = KadoKadeoManager.I(300);
	static public var GHEI = KadoKadeoManager.I(300);
	static public var TWID = KadoKadeoManager.I(25); // 25
	static public var THEI = KadoKadeoManager.I(25);
	static public var GRAVITY = KadoKadeoManager.S(0.9);
	static public var FX_GRAVITY = KadoKadeoManager.S(0.7);

	static public var PTS_TOKEN = KKApi.const(5);
	static public var AUTOUP_TIMER = KKApi.const(32 * 15);
	static public var MIN_COMBO = KKApi.const(3);
}
