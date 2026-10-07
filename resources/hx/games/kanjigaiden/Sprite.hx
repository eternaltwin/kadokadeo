package kanjigaiden;

// Sprite.hx of the original (a copy of mt.bumdum.Sprite). Port: spriteList (never read by the game, never emptied for
// the monkeys) is left out; `obj` (the MovieClip's link to its sprite) too.
class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:MC;
	public var scale:Float;

	public function new(?mc:MC) {
		root = mc;

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
		root._x = x;
		root._y = y;
	}

	public function kill() {
		root.removeMovieClip();
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
	}
}
