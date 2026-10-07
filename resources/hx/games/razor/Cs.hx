package razor;

// Cs.hx of the original (constants of the board: 6 x 6 cells of 36 px around the centre of the board)
class Cs {
	public static var mcw = 300;
	public static var mch = 300;

	public static var SIDE = 6;
	public static var size = 36;

	public static var DIR = [[1, 0], [0, 1], [-1, 0], [0, -1]];

	public static var RAZOR_SPEED = 0.25;

	public static var SCORE_FRUIT_BASE = KKApi.const(200);
	public static var SCORE_FRUIT_INC = KKApi.const(50);
	public static var SCORE_PIOUPIOU = KKApi.const(1000);

	// GAMEPLAY
	public static var COL_MAX = 3;
	public static var POOL_MAX = 4;

	public static inline function getX(x:Float) {
		return (0.5 + x - SIDE * 0.5) * size;
	}

	public static inline function getY(y:Float) {
		return (0.5 + y - SIDE * 0.5) * size;
	}
}

// mt.bumdum.Lib.Num, as the SWF compiled it
class Num {
	// (null on a modulo 0 or a null number: never the case here)
	public static function sMod(n:Float, mod:Float):Float {
		while (n >= mod)
			n -= mod;
		while (n < 0)
			n += mod;
		return n;
	}

	public static function hMod(n:Float, mod:Float):Float {
		while (n > mod)
			n -= mod * 2;
		while (n < -mod)
			n += mod * 2;
		return n;
	}
}

// mt.bumdum.Lib.Geom
class Geom {
	// the position of mc in the coordinates of `root`, through the clips between them: their rotation (in radians as
	// _rotation * 0.0174, not PI / 180: kept, the razor and the splashes are drawn where Flash drew them), scale and
	// position. The game root has no transform (flash.Lib.current at the origin of the KadoKado loader)
	public static function getParentCoord(mc:MC):{x:Float, y:Float} {
		var x = mc._x;
		var y = mc._y;
		var p = mc.parentMC;
		while (p != null) {
			if (p._rotation != 0) {
				var dist = Math.sqrt(x * x + y * y);
				var a = Math.atan2(y, x);
				a += p._rotation * 0.0174;
				x = Math.cos(a) * dist;
				y = Math.sin(a) * dist;
			}
			x *= p._xscale * 0.01;
			y *= p._yscale * 0.01;
			x += p._x;
			y += p._y;
			p = p.parentMC;
		}
		return {x: x, y: y};
	}
}
