package popcorn;

import pixi.filters.colormatrix.ColorMatrixFilter;
import pixi.core.math.Matrix;
import pixi.core.textures.RenderTexture;
import common_haxe_avm1.KKApi;
import kado.KadoKadeoManager;

class Cs {
	public static var NEW_GEN_SCALE = 3;
	public static var mcw = 300 * NEW_GEN_SCALE;
	public static var mch = 300 * NEW_GEN_SCALE;

	public static var HEIGHT = 900 * NEW_GEN_SCALE; // 1000;
	public static var MARGIN = 0;

	public static var COMBO = KKApi.aconst([25, 50, 75, 100, 150, 200, 300, 400, 500]);
	public static var SCORE_BOSS = KKApi.const(50000);
	public static var SCORE_HIT = KKApi.const(5000);

	public static var DIR = [{x: 1, y: 0}, {x: 0, y: 1}, {x: -1, y: 0}, {x: 0, y: -1}];

	// COLOR MATRIX
	public static var CM_GREY = [];
	public static var CM_STD = [];

	//
	public static var game:Game;

	public static function init():Void {
		// COLOR MATRIX
		var r = 0.3;
		var g = 0.5;
		var b = 0.1;
		var a = 30;
		CM_GREY = [
			r, g, b, 0, a,
			r, g, b, 0, a,
			r, g, b, 0, a,
			0, 0, 0, 1, 0
		];

		//
		CM_STD = [
			1, 0, 0, 0, 0,
			0, 1, 0, 0, 0,
			0, 0, 1, 0, 0,
			0, 0, 0, 1, 0
		];
	}

	public static function draw(bmp:RenderTexture, mc:ASprite):Void {
		var m = new Matrix();

		m.scale(mc._xscale / 100, mc._yscale / 100);
		m.rotate(mc._rotation * 0.0174);
		m.translate(mc._x, mc._y);

		var ctFilter = new ColorMatrixFilter();
		ctFilter.matrix = [
			1, 0, 0, 0,                              0, // R
			0, 1, 0, 0,                              0, // G
			0, 0, 1, 0,                              0, // B
			0, 0, 0, 1, -255 + mc._alpha * 2.55, // A offset
		];
		mc.filters = [ctFilter];
		bmp.draw(mc, m);
	}

	public static inline function rand():Float {
		return KadoKadeoManager.kkm.seed.rand();
	}

	public static inline function random(max:Int):Int {
		if (max <= 0)
			return 0;
		return KadoKadeoManager.kkm.seed.random(max);
	}

	// COLOR MATRIX
	public static function getGreyMatrix(a:Float):Array<Float> {
		var r = 0.3;
		var g = 0.5;
		var b = 0.1;
		return [
			r, g, b, 0, a / 255,
			r, g, b, 0, a / 255,
			r, g, b, 0, a / 255,
			0, 0, 0, 1,       0
		];
	}

	// COLOR
	// public static function setColor(mc:ASprite, col:Int, dec:Float) {
	// 	if (dec == null)
	// 		dec = -255;
	// 	var o = colToObj32(col);
	// 	var co = new Color(mc);
	// 	var ct = {
	// 		ra: 100,
	// 		ga: 100,
	// 		ba: 100,
	// 		aa: 100,
	// 		rb: o.r + dec,
	// 		gb: o.g + dec,
	// 		bb: o.b + dec,
	// 		ab: 0
	// 	};
	// 	co.setTransform(ct);
	// }
	// public static function colToObj32(col:Int) {
	// 	return {
	// 		a: col >>> 24,
	// 		r: (col >> 16) & 0xFF,
	// 		g: (col >> 8) & 0xFF,
	// 		b: col & 0xFF
	// 	};
	// }
}
