package ironchouquette;

import common_haxe_avm1.KKApi;
import pixi.core.textures.RenderTexture;
import pixi.core.math.Matrix;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var mcw = 300 * Cs.NEW_GEN_SCALE;
	public static var mch = 300 * Cs.NEW_GEN_SCALE;

	// GAMEPLAY
	public static var CDIF = 0.7; // 0.7;

	// SCORES
	public static var SCORE_ASTEROID = KKApi.aconst([50, 75, 150, 200, 300]);
	public static var C5 = KKApi.const(5);
	public static var C0 = KKApi.const(0);
	public static var C500 = KKApi.const(500);

	public static var C_OMEGA = KKApi.const(65);
	public static var C_BLACKRON = KKApi.const(80);
	public static var C_FURIA = KKApi.const(120);
	public static var C_CUTTY_OPEN = KKApi.const(200);
	public static var C_MINE = KKApi.const(300);
	public static var C_BRIAROS = KKApi.const(350);
	public static var C_GROMPH = KKApi.const(450);
	public static var C_SHIELD = KKApi.const(500);
	public static var C_CUTTY_CLOSE = KKApi.const(600);
	public static var C_ORB = KKApi.const(800);
	public static var C_BLOCK = KKApi.const(1000);
	public static var C_SURGROMPH = KKApi.const(1500);
	public static var C_GERGIN = KKApi.const(2400);
	public static var C_NES = KKApi.const(5000);
	public static var C_STORM = KKApi.aconst([2000, 3500, 8000]);

	//
	public static var game:Game;

	public static function init() {}

	// COLOR
	public static function colToObj32(col) {
		return {
			a: col >>> 24,
			r: (col >> 16) & 0xFF,
			g: (col >> 8) & 0xFF,
			b: col & 0xFF
		};
	}

	// DIST ANG
	public static function getDist(o1, o2) {
		var dx = o1.x - o2.x;
		var dy = o1.y - o2.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public static function getAng(o1, o2) {
		var dx = o1.x - o2.x;
		var dy = o1.y - o2.y;
		return Math.atan2(dy, dx);
	}

	// CHAIN MC COMMAND
	public static function allGoto(mc:ASprite, key:String, fr:Int) {
		trace("FIXME: allGoto", key, fr);
		// var f = fun(str) {
		// 	var mmc:ASprite = Std.getVar(mc, str);
		// 	if (mmc._visible) {
		// 		if (str.substr(0, key.length) == key) {
		// 			mmc.gotoAndStop(Std.string(fr));
		// 		}
		// 		allGoto(mmc, key, fr);
		// 	}
		// };
		// downcast(Std).forin(mc, f);
	}
}
