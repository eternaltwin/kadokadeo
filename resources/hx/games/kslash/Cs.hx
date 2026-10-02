package kslash;

import pixi.filters.colormatrix.ColorMatrixFilter;

class Cs {
	public static inline var SIZE = 24;
	public static inline var PLAT_ECART = 4;

	public static inline var ST_NORMAL = 0;
	public static inline var ST_CLIMB = 1;
	public static inline var ST_FLY = 2;
	public static inline var ST_DEATH = 3;
	public static inline var ST_SHOOT = 4;

	public static inline var OPT_KATANA = 0;
	public static inline var OPT_FLAMES = 1;
	public static inline var OPT_SCROLL = 2;

	public static var mcw = 300;
	public static var mch = 300;

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

	// gameplay values computed with trigonometry or powers are rounded (1/65536 px, an exact binary fraction): the
	// replays stay identical on every browser even if their Math functions differ in the last bits
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	// Cs.setPercentColor of the original (ColorTransform: (100 - prc)% of the colour + prc% of col), no filter at 0
	public static function setPercentColor(mc:ASprite, prc:Float, col:Int) {
		var cm:ColorMatrixFilter = Reflect.field(mc, "__pc");
		if (prc == 0) {
			if (cm != null && mc.filters != null) {
				var l = [for (f in mc.filters) if (f != cm) f];
				mc.filters = l.length > 0 ? l : null;
			}
			return;
		}
		if (cm == null) {
			cm = new ColorMatrixFilter();
			Reflect.setField(mc, "__pc", cm);
		}
		// Flash rounds the multipliers and offsets to integers (percent / 0..255)
		var m = Std.int(100 - prc) / 100;
		var c = prc / 100;
		var r = Std.int(c * (col >> 16)) / 255;
		var g = Std.int(c * ((col >> 8) & 0xFF)) / 255;
		var b = Std.int(c * (col & 0xFF)) / 255;
		cm.matrix = [m, 0, 0, 0, r, 0, m, 0, 0, g, 0, 0, m, 0, b, 0, 0, 0, 1, 0];
		var fl:Array<Dynamic> = mc.filters != null ? [for (f in mc.filters) f] : [];
		if (fl.indexOf(cm) < 0)
			fl.unshift(cm);
		mc.filters = cast fl;
	}
}
