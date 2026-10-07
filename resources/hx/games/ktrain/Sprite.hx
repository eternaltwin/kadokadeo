package ktrain;

// mt.bumdum.Sprite (libs-haxe2, as compiled in the released game.swf): a clip moved at (x, y), updated by Game.update
class Sprite {
	public static var spriteList:Array<Sprite> = [];

	public var x:Float;
	public var y:Float;
	public var root:MC;
	public var scale:Float;

	public function new(mc:MC) {
		root = mc;
		root.obj = this;
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

	public function update() {
		updatePos();
	}

	public function kill() {
		root.removeMovieClip();
		spriteList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
	}
}
