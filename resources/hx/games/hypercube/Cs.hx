package hypercube;

class Cs {
	public static inline var mcw = 300;
	public static inline var mch = 300;

	public static inline var SHAPE_SIZE = 5;
	public static inline var SHAPE_VOLUME = 4;

	public static inline var COMBO_MIN = 3;

	public static inline var PIECE_SPEED = 5;
	public static inline var PIECE_INTERVAL = 80;

	public static inline var TIMER_MAX = 5000; // 7000

	public static var C100 = KKApi.const(100);

	// Color.setTransform as Flash applies it: multipliers in percent truncated to 1/256, offsets in 0..255
	public static function setPercentColor(mc:MC, prc:Float, col:Int) {
		var color = {
			r: col >> 16,
			g: (col >> 8) & 0xFF,
			b: col & 0xFF
		};
		var c = prc / 100;
		var ra = Std.int(100 - prc);
		mc.setColorTransform(Std.int(ra * 2.56) / 256, Std.int(c * color.r), Std.int(c * color.g), Std.int(c * color.b));
	}

	// gameplay values computed with trigonometry: rounded to 1/65536 (the last bits of Math.cos / sin / atan2 / pow
	// can differ between browsers; the replays must not)
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}

	// (makeButton: the end button is a Flash Button whose states are drawn by Buttons; its gotoAndStop calls did
	// nothing)
}
