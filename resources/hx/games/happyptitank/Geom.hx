package happyptitank;

// (the original's functions take anything with x and y: points and display objects, whose x / y go through their
// Flash properties, twips included)
abstract Pt(Dynamic) from DisplayObject from Point from {x:Float, y:Float} {
	public var x(get, set):Float;
	public var y(get, set):Float;

	inline function get_x():Float {
		var d = Std.downcast(this, DisplayObject);
		return d != null ? d.x : this.x;
	}

	inline function set_x(v:Float):Float {
		var d = Std.downcast(this, DisplayObject);
		if (d != null)
			d.x = v;
		else
			this.x = v;
		return v;
	}

	inline function get_y():Float {
		var d = Std.downcast(this, DisplayObject);
		return d != null ? d.y : this.y;
	}

	inline function set_y(v:Float):Float {
		var d = Std.downcast(this, DisplayObject);
		if (d != null)
			d.y = v;
		else
			this.y = v;
		return v;
	}
}

typedef _Ptx = {x:Float, y:Float};

class Geom {
	public static inline function radToVector(rad:Float):_Ptx {
		var result = {x: 0.0, y: 0.0};
		moveAngle(result, rad, 1.0);
		return result;
	}

	public static inline function rad2deg(rad:Float):Float {
		return rad * 180 / Math.PI;
	}

	public static inline function deg2rad(deg:Float):Float {
		return deg * Math.PI / 180;
	}

	public static inline function middle(a:Pt, b:Pt):_Ptx {
		return {
			x: a.x + (b.x - a.x) / 2,
			y: a.y + (b.y - a.y) / 2
		};
	}

	public static inline function distance(a:Pt, b:Pt):Float {
		return Math.sqrt(Math.pow(b.x - a.x, 2) + Math.pow(b.y - a.y, 2));
	}

	public static inline function angleRad(a:Pt, b:Pt):Float {
		var dx = b.x - a.x;
		var dy = b.y - a.y;
		return Math.atan2(dy, dx);
	}

	public static inline function angleDeg(a:Pt, b:Pt):Float {
		return rad2deg(angleRad(a, b));
	}

	public static inline function rotate(a:Pt, rad:Float) {
		var cos = Math.cos(rad);
		var sin = Math.sin(rad);
		var b = {
			x: a.x * cos - a.y * sin,
			y: a.x * sin + a.y * cos
		};
		a.x = b.x;
		a.y = b.y;
	}

	public static inline function moveAngle(a:Pt, rad:Float, speed:Float) {
		a.x += speed * Math.cos(rad);
		a.y += speed * Math.sin(rad);
	}

	public static inline function fixRadianAngle(rad:Float):Float {
		if (rad < 0)
			rad = Math.PI * 2 - Math.abs(rad % (Math.PI * 2));
		if (rad > Math.PI * 2)
			rad = rad % (Math.PI * 2);
		return rad;
	}

	public static inline function averageRadianAngle(a0:Float, a1:Float):Float {
		return if (Math.abs(a0 - a1) > Math.PI) fixRadianAngle((a0 - 2 * Math.PI + a1) / 2); else fixRadianAngle((a0 + a1) / 2);
	}

	public static inline function angleDiff(a0:Float, a1:Float):Float {
		var bigger = Math.max(a0, a1);
		var smaller = Math.min(a0, a1);
		var dist = bigger - smaller;
		return if (dist > Math.PI) Math.PI * 2 - dist else dist;
	}
}
