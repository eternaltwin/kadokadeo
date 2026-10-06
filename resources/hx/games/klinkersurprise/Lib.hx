package klinkersurprise;

// the helpers of mt.bumdum.Lib the original uses, as compiled in the released game.swf (the library changed later:
// sMod returned null on a bad modulo, the compiled one returns the number; hMod has no check at all)
class Num {
	public static function sMod(n:Float, mod:Float):Float {
		// (the trace "sMod ERROR!" of the original)
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

	public static function mm(a:Float, b:Float, c:Float):Float {
		return Math.min(Math.max(a, b), c);
	}
}

typedef Rgb = {r:Int, g:Int, b:Int};
typedef Argb = {a:Int, r:Int, g:Int, b:Int};

class Col {
	public static function colToObj(col:Int):Rgb {
		return {r: col >> 16, g: (col >> 8) & 0xFF, b: col & 0xFF};
	}

	public static function objToCol(o:Rgb):Int {
		return (o.r << 16) | (o.g << 8) | o.b;
	}

	// (a = 1000 for the white of Game.paint: 1000 << 24 keeps its low byte, alpha 0xE8, like the 32 bits of AVM1)
	public static function objToCol32(o:Argb):Int {
		return (o.a << 24) | (o.r << 16) | (o.g << 8) | o.b;
	}
}
