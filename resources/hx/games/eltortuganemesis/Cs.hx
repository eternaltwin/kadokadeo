package eltortuganemesis;

class Cs {
	// trigonometry of the gameplay rounded to 1e-9: the same on every browser (replays)
	public static inline function qt(v:Float):Float {
		return Math.round(v * 1e9) / 1e9;
	}

	public static inline function cos(a:Float):Float {
		return qt(Math.cos(a));
	}

	public static inline function sin(a:Float):Float {
		return qt(Math.sin(a));
	}

	public static inline function atan2(y:Float, x:Float):Float {
		return qt(Math.atan2(y, x));
	}
}

// colours of the move zone (ARGB, as signed 32 bits like the Int32Array of Bmp)
class Colors {
	public static inline var TO_CONQUER:Int = 0xFF000000;
	public static inline var CONQUERED_ZONE:Int = 0xFF020301;
	public static inline var CONQUERED_ZONE_FAST:Int = 0xFF020201;
	public static inline var CONQUERED_PATH:Int = 0xFFA1A301;
	public static inline var CONQUERED_PATH_FAST:Int = 0xFF01A201;
	public static inline var OUTSIDE:Int = 0xFF011001;
	public static inline var DRAWING_PATH_SLOW:Int = 0xFFAA7777;
	public static inline var DRAWING_PATH_FAST:Int = 0xFF777777;
	public static inline var BORDER_GRASS_BG:Int = 0xFF556600;
	public static inline var GRASS_BG:Int = 0xFF557700;
	public static inline var FLASH_COLOR:Int = 0xFFFF0000;

	public static inline function isDrawingPath(c:Int):Bool {
		return c == DRAWING_PATH_SLOW || c == DRAWING_PATH_FAST;
	}

	public static inline function isConqueredZone(c:Int):Bool {
		return c == CONQUERED_ZONE || c == CONQUERED_ZONE_FAST;
	}

	public static inline function isConqueredPath(c:Int):Bool {
		return c == CONQUERED_PATH || c == CONQUERED_PATH_FAST;
	}

	public static inline function isConqueredSlow(c:Int):Bool {
		return c == CONQUERED_PATH || c == CONQUERED_ZONE;
	}

	public static inline function isConqueredFast(c:Int):Bool {
		return c == CONQUERED_PATH_FAST || c == CONQUERED_ZONE_FAST;
	}
}

class Level {
	public var goal:Int;
	public var dogSpeed:Float;
	public var dogLazerLength:Float;
	public var dogLazerSpeed:Float;
	public var sparksSpeed:Float;
	public var lazerSparkSpeed:Float;
	public var lazerSparkDelay:Float;

	public function new() {}

	static var data:Array<Level>;

	static function make(goal:Int, dog:Float, len:Float, lspeed:Float, sparks:Float, lsp:Float, delay:Float) {
		var l = new Level();
		l.goal = goal;
		l.dogSpeed = dog * Game.FAST_SPEED;
		l.dogLazerLength = len;
		l.dogLazerSpeed = lspeed;
		l.sparksSpeed = sparks * Game.FAST_SPEED;
		l.lazerSparkSpeed = lsp * Game.SLOW_SPEED;
		l.lazerSparkDelay = delay;
		return l;
	}

	public static function get(idx:Int):Level {
		if (data == null)
			data = [
				make(50, 0.9, 110, 5, 0.5, 0.6, 2000.0),
				make(60, 1.1, 115, 5.5, 0.7, 0.7, 1800.0),
				make(70, 1.3, 120, 6, 1, 0.8, 1600.0),
				make(75, 1.5, 120, 6.5, 1.1, 0.9, 1400.0),
				make(80, 1.7, 120, 7, 1.2, 1.0, 1200.0),
				make(85, 1.8, 120, 7.5, 1.3, 1.1, 1000.0),
				make(90, 1.9, 125, 8, 1.4, 1.2, 800.0),
				make(90, 1.9, 130, 8, 1.5, 1.3, 800.0),
				make(90, 2.0, 135, 8, 1.6, 1.4, 800.0),
				make(90, 2.1, 140, 8, 1.7, 1.5, 800.0),
				make(90, 2.2, 150, 8, 1.8, 1.5, 800.0),
			];
		return data[Std.int(Math.min(data.length - 1, idx))];
	}
}

typedef StatZone = {size:Int, nSlow:Int, nFast:Int, value:Int};

class GameLevelStat {
	public var slow:Int;
	public var fast:Int;
	public var empty:Int;
	public var n:Int;
	public var pcent:Float;
	public var goal:Float;
	public var list:List<StatZone>;
	public var lastZone:StatZone;
	public var score:Float;

	public function new() {
		slow = 0;
		fast = 0;
		empty = 0;
		n = 0;
		pcent = 0.0;
		goal = 0.0;
		score = 0.0;
		list = new List();
	}

	public function update(newSlow:Int, newFast:Int, newEmpty:Int, newTotal:Int, goal:Float) {
		this.goal = goal;
		n = newTotal;
		if (newSlow != slow || newFast != fast) {
			lastZone = {
				size: empty - newEmpty,
				nSlow: newSlow - slow,
				nFast: newFast - fast,
				value: 0
			};
			lastZone.value = Math.round(lastZone.nSlow * lastZone.nSlow * 0.002 + lastZone.nFast * lastZone.nFast * 0.001);
			list.push(lastZone);
			score += lastZone.value;
		}
		empty = newEmpty;
		slow = newSlow;
		fast = newFast;
		pcent = (n == 0) ? 0.0 : Math.round(((n - empty) / n) * 1000) / 10;
	}
}
