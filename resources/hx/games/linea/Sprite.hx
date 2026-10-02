package linea;

// mt.bumdum.Sprite of the original (as compiled in the released game.swf): the position is kept in x / y and copied
// to the clip at each update
class Sprite {
	public static var spriteList:Array<Sprite> = [];

	public var root:MC;
	public var x:Float;
	public var y:Float;
	public var scale:Float;

	public function new(mc:MC) {
		root = mc;
		root.obj = this;
		spriteList.push(this);
		x = root._x;
		y = root._y;
		// a clip at the origin is hidden until its first update
		if (root._x == 0 && root._y == 0) {
			root._x = -100;
			root._y = -100;
			x = 0;
			y = 0;
		}
		scale = 100;
	}

	public function update():Void {
		updatePos();
	}

	public function updatePos():Void {
		root._x = x;
		root._y = y;
	}

	public function kill():Void {
		root.removeMovieClip();
		spriteList.remove(this);
	}
}
