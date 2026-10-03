package magmax;

/**
 * Std.hitTest(a, b) of the original is Flash's a.hitTest(b): the bounds of the two clips in the stage overlap.
 * Gameplay cannot read the PIXI display: the bounds come from the SWF (Data, measured by magmax_assets.py with
 * Flash's rule: every shape rectangle through its full matrix) for the frames the timelines are on, placed at the
 * _x / _y of the clips (in twips, like Flash). Rectangles are [xMin, xMax, yMin, yMax].
 */
class Bounds {
	public static inline function hit(a:Array<Float>, b:Array<Float>):Bool {
		return a[0] <= b[1] && b[0] <= a[1] && a[2] <= b[3] && b[2] <= a[3];
	}

	// a rectangle of a clip at (x, y) scaled by sx, sy (percent)
	public static function place(r:Array<Float>, x:Float, y:Float, sx:Float = 100, sy:Float = 100):Array<Float> {
		var kx = sx / 100;
		var ky = sy / 100;
		var x0 = r[0] * kx;
		var x1 = r[1] * kx;
		var y0 = r[2] * ky;
		var y1 = r[3] * ky;
		return [
			tw(x + Math.min(x0, x1)),
			tw(x + Math.max(x0, x1)),
			tw(y + Math.min(y0, y1)),
			tw(y + Math.max(y0, y1))
		];
	}

	public static function union(a:Array<Float>, b:Array<Float>):Array<Float> {
		return [Math.min(a[0], b[0]), Math.max(a[1], b[1]), Math.min(a[2], b[2]), Math.max(a[3], b[3])];
	}

	// shapes [xMin, xMax, yMin, yMax, a, b, c, d, tx, ty] of a clip turned by (cos, sin) and placed at (x, y)
	public static function turned(leaves:Array<Array<Float>>, cos:Float, sin:Float, x:Float, y:Float):Array<Float> {
		var x0 = Math.POSITIVE_INFINITY;
		var x1 = Math.NEGATIVE_INFINITY;
		var y0 = Math.POSITIVE_INFINITY;
		var y1 = Math.NEGATIVE_INFINITY;
		for (l in leaves) {
			for (k in 0...4) {
				var px = (k & 1) == 0 ? l[0] : l[1];
				var py = (k & 2) == 0 ? l[2] : l[3];
				var u = l[4] * px + l[6] * py + l[8];
				var v = l[5] * px + l[7] * py + l[9];
				var gx = cos * u - sin * v;
				var gy = sin * u + cos * v;
				if (gx < x0)
					x0 = gx;
				if (gx > x1)
					x1 = gx;
				if (gy < y0)
					y0 = gy;
				if (gy > y1)
					y1 = gy;
			}
		}
		return [tw(x + x0), tw(x + x1), tw(y + y0), tw(y + y1)];
	}

	// Flash computes the bounds in twips
	static inline function tw(v:Float):Float {
		return Math.round(v * 20) / 20;
	}
}
