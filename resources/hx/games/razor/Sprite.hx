package razor;

// mt.bumdum.Sprite of the original: the position is kept in x / y and copied to the clip at each update; a clip at the
// origin is parked at (-100, -100) until its first update
class Sprite {
	public static var spriteList:Array<Sprite> = [];

	public var x:Float;
	public var y:Float;
	public var root:MC;
	public var scale:Float;

	public function new(mc:MC) {
		root = mc;
		spriteList.push(this);
		x = root._x;
		y = root._y;
		if (root._x == 0 && root._y == 0) {
			root._x = -100;
			root._y = -100;
			x = 0;
			y = 0;
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
		root._x = x;
		root._y = y;
	}
}
