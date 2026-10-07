package punchin;

// mt.bumdum.Sprite of the original: the position is kept in x / y and copied to the clip at each update
class Sprite {
	public static var spriteList:Array<Sprite> = [];

	public var x:Float;
	public var y:Float;
	public var root:MC;
	public var scale:Float;

	// parked off screen by the constructor: its first update places it, not interpolated from the parking spot
	var parked:Bool = false;

	public function new(mc:MC) {
		root = mc;
		spriteList.push(this);
		x = root._x;
		y = root._y;
		// a clip at the origin is parked at (-100, -100) until its first update
		if (root._x == 0 && root._y == 0) {
			root._x = -100;
			root._y = -100;
			x = 0;
			y = 0;
			parked = true;
		}
		scale = 100;
	}

	public function setScale(n:Float) {
		scale = n;
		root._xscale = n;
		root._yscale = n;
	}

	public function update():Void {
		updatePos();
	}

	public function kill():Void {
		root.removeMovieClip();
		spriteList.remove(this);
	}

	public function updatePos():Void {
		if (parked) {
			parked = false;
			root.teleport(x, y);
			return;
		}
		root._x = x;
		root._y = y;
	}
}
