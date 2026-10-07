package opalusfactory;

import opalusfactory.Game.InCase;

// Cs.hx of the original
class Cs {
	// GAME SIZE
	public static var mcw = 300;
	public static var mch = 300;

	public static var GOAL_ROLL_UPWARD = 2;
	public static var GOAL_UP_LEVEL = 3;
	public static var GOLDEN_COIN = 8;
	public static var CASE_PER_LINE = 5;
	public static var INIT_LEVEL = 5;
	public static var ROLL_BOTTOM = 300;
	public static var ROLL_LENGTH = 20;
	public static var ROLL_LINE_RECAL = 25;
	public static var UP_LIMIT = 19;
	public static var DOWN_LIMIT = 3;
	public static var ROLL_LINE_Y = 14.5;
	public static var ROLL_LINE_X = 50;

	public static var HOLE_X = 315.0;
	public static var GOAL_X = 298.0;

	public static var AROUND_CASE = [
		[[0, -1], [0, 1], [1, -1], [1, 1], [0, 2], [0, -2]],
		[[-1, -1], [-1, 1], [0, -1], [0, 1], [0, 2], [0, -2]]
	];

	public static var INIT_COUNT = 2;

	// scale, y of the lines 0..4 (the bottom of the roll, seen from above)
	public static var ROLL_VOID_INFOS:Array<Array<Float>> = [
		[10.0, ROLL_BOTTOM - 22],
		[35.0, ROLL_BOTTOM - 27],
		[55.0, ROLL_BOTTOM - 34.5],
		[75.0, ROLL_BOTTOM - 44.5],
		[100, ROLL_BOTTOM - 58]
	];

	public static function getAround(c:InCase):Array<Array<Int>> {
		// (the hero's case of a fallen hero is undefined: undefined.l.recal > 0 is false)
		if (c != null && c.l.recal > 0)
			return AROUND_CASE[0];
		else
			return AROUND_CASE[1];
	}

	public static var POINTS:KKConst = KKApi.const(200);
	public static var GOAL_POINTS:KKConst = KKApi.const(600);
	public static var MULTI_BONUS:KKConst = KKApi.const(50);
	public static var GOLDEN_BONUS:KKConst = KKApi.const(12000);

	public static function getDist(x:Float, y:Float, lastX:Float, lastY:Float):Float {
		return Math.sqrt((x - lastX) * (x - lastX) + (y - lastY) * (y - lastY));
	}

	// the hero turns towards the mouse (a picture only)
	public static function rotateMc(mc:MC, x:Float, y:Float, lx:Float, ly:Float):Float {
		var a = Math.acos(Cs.getDist(x, 0, lx, 0) / Cs.getDist(x, y, lx, ly));
		var dg = 180 * a / 3.14;
		// (Haxe 2 compiles a <= b as !(a > b))
		if (!(x > lx) && !(y > ly))
			dg = 270 + dg;
		else if (x > lx && !(y > ly))
			dg = 90 - dg;
		else if (x > lx && y > ly)
			dg = 90 + dg;
		else if (!(x > lx) && y > ly)
			dg = 270 - dg;

		var r = mc._rotation;
		if (r < 0)
			r += 360;

		if (r > 270 && dg < 90)
			dg += 360;
		else if (r < 90 && dg > 270)
			r += 360;

		var p = Math.min((dg - r) / 5, 30) * mt.Timer.tmod;
		var g = Math.min(Math.abs(p), Math.abs(dg - r)) * (if (dg > r) 1 else -1);

		mc._rotation = r + g;
		return mc._rotation;
	}

	// port: a result of Math.pow that decides the game, rounded to 1/65536 (an exact binary fraction)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	// port: statics of the original changed during a game (none are, but the SWF was loaded again for every game)
	public static function init() {}
}
