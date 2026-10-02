package minirace;

// mt.bumdum.Sprite of the original
class Sprite {
	public var x:Float;
	public var y:Float;
	public var root:ASprite;
	public var scale:Float;
	public var dead:Bool;

	var placed:Bool;

	public function new(mc:ASprite) {
		root = mc;
		Cs.game.sList.push(this);
		// attached clips are at (0, 0): moved out of the screen until their first update
		x = 0;
		y = 0;
		root._x = -1000;
		root._y = -1000;
		scale = 100;
		placed = false;
		dead = false;
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
		if (dead)
			return;
		dead = true;
		root.removeMovieClip();
		Cs.game.sList.remove(this);
	}

	public function updatePos() {
		root._x = x;
		root._y = y;
		firstPlace();
	}

	// first placement: no interpolation from the hidden position
	inline function firstPlace() {
		if (!placed) {
			placed = true;
			root.updateState();
		}
	}

	public function getDist(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Math.sqrt(dx * dx + dy * dy);
	}

	public function getAng(o:{x:Float, y:Float}):Float {
		var dx = o.x - x;
		var dy = o.y - y;
		return Cs.qt(Math.atan2(dy, dx));
	}
}
