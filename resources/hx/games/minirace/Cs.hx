package minirace;

import pixi.filters.colormatrix.ColorMatrixFilter;

typedef CheckPoint = {a:Float, x:Float, y:Float};

class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var game:Game;

	public static var SCORE_ACCEL = KKApi.const(5);
	public static var SCORE_OVERTAKE = KKApi.aconst([1000, 3000, 8000]);
	public static var SCORE_PERFECT = KKApi.const(3000);
	public static var SCORE_FAST = KKApi.const(5000);
	public static var SCORE_FURIOUS = KKApi.const(8000);

	public static inline var TURN_MAX = 6;
	public static inline var LIFE_MAX = 100;
	public static inline var LAP_MALUS = 0.95;

	public static var RACE:Array<Array<Float>> = [
		[150.0, 255.0], [254, 230], [270, 223], [275, 213], [277, 199], [271, 51], [266, 36], [256, 25], [240, 24], [230, 31], [223, 45],
		[208, 143], [205, 154], [193, 159], [179, 156], [112, 122], [105, 115], [104, 106], [110, 97], [164, 59], [168, 50], [165, 42],
		[157, 39], [147, 39], [73, 41], [54, 51], [39, 69], [31, 91], [33, 111], [42, 129], [55, 140], [121, 176], [130, 184],
		[131, 194], [123, 202], [111, 207], [40, 219], [25, 232], [19, 249], [22, 264], [34, 274], [49, 277], [66, 274]
	];

	public static function init(g:Game) {
		g.checkpoints = [];

		var pa = 0.0;
		for (i in 0...RACE.length) {
			var pos = RACE[i];
			var next = RACE[(i + 1) % RACE.length];
			var na = getAng(pos, next);

			var da = hMod(na - pa, 3.14);
			var ba = pa + da * 0.5;

			g.checkpoints.push({x: pos[0], y: pos[1], a: ba + 1.57});
			pa = na;
		}
	}

	public static function getAng(p1:Array<Float>, p2:Array<Float>):Float {
		var dx = p2[0] - p1[0];
		var dy = p2[1] - p1[1];
		return qt(Math.atan2(dy, dx));
	}

	// Num.mm
	public static inline function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	// Num.hMod: brought into [-mod, mod] by steps of 2 mod (3.14 for the angles: not exactly 2 pi, like the original)
	public static function hMod(n:Float, mod:Float):Float {
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}

	// results of Math.atan2 / cos / sin used by the gameplay, rounded to 1e-9: the replays stay identical on every
	// browser even if their Math functions differ in the last bits (the rest is exact IEEE arithmetic)
	public static inline function qt(v:Float):Float {
		return Math.round(v * 1e9) / 1e9;
	}

	// Flash _rotation reads back in ]-180, 180]
	public static function normRot(r:Float):Float {
		r = r % 360;
		if (r > 180)
			r -= 360;
		if (r <= -180)
			r += 360;
		return r;
	}

	// Col.setPercentColor(mc, prc, col) of the original on a whole display tree: ColorTransform (100 - prc)% of the
	// colour + prc% of col (prc can be negative), no filter at 0
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

	// the same on a Clip without filter: multiplied grey + added colour (white silhouettes of the clip)
	public static function setPercentColorClip(mc:Clip, prc:Float, col:Int) {
		if (prc == 0) {
			mc.setColour(0xFFFFFF, 0);
			return;
		}
		var m = Std.int(100 - prc) / 100;
		var c = prc / 100;
		var mg = Std.int(Math.max(0, Math.min(255, Math.round(m * 255))));
		var r = Std.int(Math.max(0, Std.int(c * (col >> 16))));
		var g = Std.int(Math.max(0, Std.int(c * ((col >> 8) & 0xFF))));
		var b = Std.int(Math.max(0, Std.int(c * (col & 0xFF))));
		mc.setColour((mg << 16) | (mg << 8) | mg, (r << 16) | (g << 8) | b);
	}
}
