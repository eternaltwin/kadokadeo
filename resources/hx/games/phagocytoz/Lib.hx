package phagocytoz;

// the parts of mt.bumdum9.Lib (libs-haxe2) the game uses
class Num {
	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}

	public static function sMod(n:Float, mod:Float):Float {
		if (mod == 0)
			return n;
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

	// port: Math.cos / sin / atan2 / pow can differ in their last bits between browsers; the values that enter the
	// game state are rounded to 1/65536 (an exact binary fraction), so that a replay plays the same everywhere
	public static inline function q(v:Float):Float {
		return Math.round(v * 65536) / 65536;
	}
}

class Col {
	public static function objToCol(o:{r:Int, g:Int, b:Int}):Int {
		return (o.r << 16) | (o.g << 8) | o.b;
	}
}

class Filt {
	// a GlowFilter (alpha 1, quality 1) added to the filters of the object
	public static function glow(mc:DisplayObject, ?bl:Float, ?str:Float, ?col:Int, ?inner:Bool) {
		if (bl == null)
			bl = 2;
		if (str == null)
			str = 10;
		if (col == null)
			col = 0;
		if (inner == null)
			inner = false;
		var a = mc.filters != null ? mc.filters.copy() : [];
		a.push({
			type: "glow",
			blurX: bl,
			blurY: bl,
			strength: str,
			color: col,
			inner: inner,
			passes: 1
		});
		mc.filters = a;
	}
}
