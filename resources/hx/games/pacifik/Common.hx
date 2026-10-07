package pacifik;

// (mt.flash.Volatile / KKApi.const values of the original: kept as KKApi constants)
class Const {
	public static var DP_BG = 1;
	public static var DP_BALL = 2;
	public static var DP_CANON = 3;

	public static var HEIGHT = 300;
	public static var CANONS = 1;
	public static var CANON_STARTPOS = 10;
	public static var CANON_WIDTH = 32;
	public static var CANON_HIT_POS = 40;

	public static var MAX_CANONS = KKApi.const(12);
	public static var CANON_SPACE = HEIGHT / KKApi.val(MAX_CANONS);

	public static var CANON_REPLACE_CYCLE = KKApi.const(350);
	public static var BALL_SPEED_CYCLE = KKApi.const(90);
	// changed during a game (BALL_SPEED, FIRE_CYCLE, LEARN_STEP): reset for every game, see reset
	public static var BALL_SPEED = KKApi.const(100);
	public static var BALL_SPEED_ADD = KKApi.const(3);
	public static var LASER_OFF = KKApi.const(37);
	public static var BALL1 = KKApi.const(100);
	public static var BALL2 = KKApi.const(200);
	public static var BALL3 = KKApi.const(400);
	public static var BONUS_BALL = KKApi.const(800);
	public static var BALL1_PROBA = KKApi.const(5);
	public static var BALL2_PROBA = KKApi.const(40);
	public static var BALL3_PROBA = KKApi.const(5);
	public static var BONUS_BALL_PROBA = KKApi.const(5);
	public static var FIRE_CYCLE = KKApi.const(700);
	public static var FIRE_CYCLE_MINUS = KKApi.const(2);
	public static var CAR_CYCLE = KKApi.const(800);
	public static var LEARN_CYCLE = KKApi.const(1000);
	public static var LEARN_STEP = KKApi.const(0);
	public static var SHIELD = KKApi.const(2);
	public static var CAR_ENERGY = KKApi.const(2);

	public static var COLORS = [0xFFFF66, 0xFF66FF, 0x33FFFF];

	// the SWF was loaded again for every game: the statics the game changes get their first value back
	public static function reset() {
		BALL_SPEED = KKApi.const(100);
		FIRE_CYCLE = KKApi.const(700);
		LEARN_STEP = KKApi.const(0);
	}

	// Const.COLORS[i] of the original: undefined out of the array (a bonus ball is of type 4), which Flash turns into
	// black for a colour (GlowFilter color, TextField.textColor)
	public static function color(i:Int):Int {
		return i >= 0 && i < COLORS.length ? COLORS[i] : 0;
	}

	// trigonometry whose result enters the game state, rounded (Math.sin / cos / atan2 can differ in their last bits
	// from one browser to another)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	// hit(m1, m2): the bounding boxes in the root (getBounds(Game.game.root)) intersect (flash.geom.Rectangle.intersects)
	public static function hit(r1:Array<Float>, r2:Array<Float>):Bool {
		if (r1 == null || r2 == null)
			return false;
		return r2[0] < r1[1] && r1[0] < r2[1] && r2[2] < r1[3] && r1[2] < r2[3];
	}

	// flash.geom.Rectangle.contains of a getBounds rectangle (x0, x1, y0, y1)
	public static function contains(r:Array<Float>, x:Float, y:Float):Bool {
		if (r == null)
			return false;
		return x >= r[0] && x < r[1] && y >= r[2] && y < r[3];
	}

	// a rectangle (x0, x1, y0, y1) through the matrix (a, b, c, d, tx, ty): its bounding box, in twips like Flash's
	public static function through(r:Array<Float>, a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float):Array<Float> {
		var x0 = Math.POSITIVE_INFINITY, x1 = Math.NEGATIVE_INFINITY, y0 = Math.POSITIVE_INFINITY, y1 = Math.NEGATIVE_INFINITY;
		for (px in [r[0], r[1]])
			for (py in [r[2], r[3]]) {
				var x = a * px + c * py + tx;
				var y = b * px + d * py + ty;
				if (x < x0)
					x0 = x;
				if (x > x1)
					x1 = x;
				if (y < y0)
					y0 = y;
				if (y > y1)
					y1 = y;
			}
		return [tw(x0), tw(x1), tw(y0), tw(y1)];
	}

	public static function union(a:Array<Float>, b:Array<Float>):Array<Float> {
		return [Math.min(a[0], b[0]), Math.max(a[1], b[1]), Math.min(a[2], b[2]), Math.max(a[3], b[3])];
	}

	static inline function tw(v:Float):Float {
		return Math.round(v * 20) / 20;
	}

	// the matrix of a clip's _rotation (degrees) and scales (percent): a, b, c, d
	public static function rotMatrix(rot:Float, xs:Float = 100, ys:Float = 100):Array<Float> {
		var r = rot * Math.PI / 180;
		var c = q(Math.cos(r)), s = q(Math.sin(r));
		return [c * xs / 100, s * xs / 100, -s * ys / 100, c * ys / 100];
	}
}
