package interwheel;

import common_haxe_avm1.KKApi;
import pixi.core.textures.RenderTexture;
import pixi.core.math.Matrix;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var SIDE = 10 * NEW_GEN_SCALE;
	public static var SPACE = 8 * NEW_GEN_SCALE;

	public static var VIEW_WHEEL = 50;
	public static var START_WHEEL_ID = 10;
	// GAMEPLAY
	public static var WMAX = 50;
	public static var DIF = 120;

	public static var WHEEL_SPEED_MIN = 0.05;
	public static var WHEEL_SPEED_MAX = 0.25;
	public static var WHEEL_SPEED_RANDOM = 0.05;

	public static var WHEEL_DIST_MIN = 60 * NEW_GEN_SCALE;
	public static var WHEEL_DIST_MAX = 120 * NEW_GEN_SCALE;

	public static var WHEEL_RAY_MIN = 8 * NEW_GEN_SCALE;
	public static var WHEEL_RAY_MAX = 32 * NEW_GEN_SCALE;
	public static var WHEEL_RAY_RANDOM = 50;
	public static var MINE_SPACE = 36;

	public static var DIF_RANDOMIZER = 0.1;

	public static var WATER_TIMER = 0;
	public static var WATER_SPEED = 1 * NEW_GEN_SCALE;
	public static var WATER_SPEED_INC = 0.0003;
	public static var DROWN_LIMIT = 100 * NEW_GEN_SCALE;

	// SCORE
	public static var SCORE_PASTILLE = KKApi.aconst([250, 1000, 5000]); // KKApi.const(150)

	public static var game:Game;

	public static function init() {}

	public static inline function rand():Float {
		return game.kkm.seed.rand();
	}

	public static inline function random(max:Int):Int {
		return game.kkm.seed.random(max);
	}

	public static function mm(a, b, c) {
		return Math.min(Math.max(a, b), c);
	}

	public static function sMod(v:Float, mod:Float) {
		while (v >= mod)
			v -= mod;
		while (v < 0)
			v += mod;
		return v;
	}

	public static function hMod(v:Float, mod:Float) {
		while (v > mod)
			v -= mod * 2;
		while (v < -mod)
			v += mod * 2;
		return v;
	}

	public static function getDist(o:{x:Float, y:Float}, o2:{x:Float, y:Float}) {
		var dx = o2.x - o.x;
		var dy = o2.y - o.y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	//
	public static function drawMcAt(bmp:RenderTexture, mc, x, y) {
		var m = new Matrix();
		m.translate(x, y);
		bmp.draw(mc, m);
	}
}
