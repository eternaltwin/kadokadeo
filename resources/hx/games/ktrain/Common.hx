package ktrain;

import ktrain.MC.Rect;

// Common.hx of the original (Haxe for Flash 8): the directions of the driver and the constants. The typedefs of the
// clips (Ob, DOb, Idx, Bmp) are fields of MC.
enum Dir {
	Up;
	Left;
	Right;
	Down;
	UpLeft;
	UpRight;
	DownLeft;
	DownRight;
}

class Const {
	public static var DP_BG = 1;
	public static var DP_SHADOW = 2;
	public static var DP_DECOR = 3;
	public static var DP_FOOT = 4;
	public static var DP_RAIL = 5;
	public static var DP_LIMIT = 6;
	public static var DP_GEM = 7;
	public static var DP_MAN = 8;
	public static var DP_PIOUZ = 9;
	public static var DP_LOCO = 10;
	public static var DP_SPARK = 11;
	public static var DP_SMOKE = 12;
	public static var DP_OBJECTS = 13;
	public static var DP_TUNNEL = 14;
	public static var DP_STATION = 15;
	public static var DP_PANNEAUX = 16;
	public static var DP_INTER = 17;

	public static var CENTER_X = 150;
	public static var HEIGHT = 300;
	public static var RAIL_H = 120;
	public static var LOCO_STARTPOS = 298;
	public static var LOCO_H = 147;
	public static var TR = 100;
	public static var ADD_OBJECTS = 120;
	public static var OBJECTS = -150;
	public static var FRAME_RATE = 40;
	public static var BASE_SCORE = KKApi.const(3);
	public static var MAN_OUT = 30;

	public static var MAX_SPEED = 16.0; // == hauteur MC
	public static var SPEED = 0.0;
	public static var SPEED_DIFF = 0.1;
	public static var SPEED_CYCLE = 20;
	public static var NEXT_SPEED = 1.0;
	public static var STEP_SPEED = 1;

	public static var SCENE_RANDOM = 20;
	public static var SCENE_BASE = 30;

	public static var STATION_HEIGHT = 177;
	public static var STATION_TRIGGER = 400;
	public static var STATION_BASE = 800;

	public static var MAN_SPEED = 3;

	public static var P1 = 800;
	public static var P2 = 650;
	public static var P3 = 350;

	public static var PIOUZ_RANDOM = KKApi.const(200);
	public static var COAL_BASE = KKApi.const(300);
	public static var STATION_COAL = KKApi.const(2);
	public static var NEXT_STATION = KKApi.const(5200);
	public static var OPP_SPEED = KKApi.const(5);
	public static var OPP_CYCLE = KKApi.const(5000);
	public static var OPP_START = KKApi.const(20000);
	public static var OPP_POS = KKApi.const(40);

	public static var ADD_GEM = KKApi.const(1500);
	public static var ADD_GEM_F1 = KKApi.const(1);
	public static var ADD_GEM_F2 = KKApi.const(2);
	public static var ADD_GEM_F3 = KKApi.const(3);

	public static var Ea:Array<Int> = [1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 5, 5, 6, 6, 6];
	public static var Sa:Array<Int> = [1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 4];
	public static var Ga:Array<Int> = [1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 8, 8];
	public static var Gems:Array<Int> = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 3, 3];

	public static var GEM1 = KKApi.const(5000);
	public static var GEM2 = KKApi.const(8000);
	public static var GEM3 = KKApi.const(12000);
	public static var PIOUZ = KKApi.const(24000);

	// port: the statics the game changes (the SWF was loaded again for every game)
	public static function reset() {
		SPEED = 0.0;
		NEXT_SPEED = 1.0;
		STEP_SPEED = 1;
		OPP_SPEED = KKApi.const(5);
	}

	// (the original translates the clip's own position: see Bmp.draw)
	public static function getMatrixFromMc(mc:MC, tx = 0.0, ty = 0.0):Array<Float> {
		return [mc._x + tx, mc._y + ty];
	}

	public static function hit(m1:MC, m2:MC):Bool {
		var r1 = getRectangle(m1);
		var r2 = getRectangle(m2);
		return intersects(r2, r1);
	}

	// getRectangle of a hit zone (mc.hit1, mc.hit2, mc.smc): its getBounds
	public static function hitSub(m1:MC, child1:String, m2:MC):Bool {
		var r1 = m1 == null ? null : m1.getSubBounds(child1);
		var r2 = getRectangle(m2);
		return intersects(r2, r1);
	}

	public static function getRectangle(mc:MC):Rect {
		return mc == null ? null : mc.getBounds();
	}

	// flash.geom.Rectangle.intersects: the rectangles overlap (touching does not count); a removed clip (undefined
	// bounds: NaN) or an empty one (no bounds) never does
	public static function intersects(a:Rect, b:Rect):Bool {
		if (a == null || b == null)
			return false;
		return a[0] < b[2] && a[2] > b[0] && a[1] < b[3] && a[3] > b[1];
	}

	// ---------------------------------------------------------------- port
	// Std.random of Haxe for Flash 8: the AS2 random(n) (n truncated to an integer, 0 when n <= 0 or not a number), on the
	// random of the gameplay
	public static function random(n:Float):Int {
		if (!(n >= 1))
			return 0;
		return Seed.random(Std.int(n));
	}

	// the same for what only changes pictures (smoke, sparks, debris, feathers)
	public static function randomVfx(n:Float):Int {
		if (!(n >= 1))
			return 0;
		return Seed.randomVfx(Std.int(n));
	}

	// Math.pow, sin, cos, atan2 of the gameplay rounded (they may differ in the last bits between browsers)
	public static inline function q(v:Float):Float {
		return Math.round(v * 4294967296.0) / 4294967296.0;
	}
}
